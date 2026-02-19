import json
import os
import traceback
import uuid
from decimal import Decimal
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional, Union

import boto3
from botocore.exceptions import ClientError
from boto3.dynamodb.conditions import Key


_DEFAULT_HEADERS = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,X-Amz-User-Agent",
    "Access-Control-Allow-Methods": "DELETE,GET,HEAD,OPTIONS,PATCH,POST,PUT",
    "Content-Type": "application/json",
}


def _json_default(o: Any):
    if isinstance(o, set):
        try:
            return sorted(o)
        except TypeError:
            return list(o)
    if isinstance(o, Decimal):
        # DynamoDB may return Decimal for numbers.
        if o % 1 == 0:
            return int(o)
        return float(o)
    raise TypeError(f"Object of type {type(o).__name__} is not JSON serializable")


def _json_dumps(value: Any) -> str:
    return json.dumps(value, ensure_ascii=False, default=_json_default)


def _response(
    status_code: int,
    body: Optional[Union[Dict[str, Any], List[Any], str]] = None,
    headers: Optional[Dict[str, str]] = None,
):
    merged_headers = dict(_DEFAULT_HEADERS)
    if headers:
        merged_headers.update(headers)

    if body is None:
        body_json = ""
    elif isinstance(body, (dict, list)):
        body_json = _json_dumps(body)
    else:
        body_json = _json_dumps({"message": str(body)})

    return {
        "statusCode": status_code,
        "headers": merged_headers,
        "body": body_json,
    }


def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def _now_epoch_seconds() -> int:
    return int(datetime.now(timezone.utc).timestamp())


def _parse_json_body(event) -> Dict[str, Any]:
    body = event.get("body")
    if body is None or body == "":
        return {}
    try:
        return json.loads(body)
    except json.JSONDecodeError:
        raise ValueError("Invalid JSON body")


def _get_user_id(event) -> Optional[str]:
    identity = (event.get("requestContext") or {}).get("identity") or {}
    provider = identity.get("cognitoAuthenticationProvider") or ""
    if "CognitoSignIn:" in provider:
        # ...:CognitoSignIn:<userPoolSub>
        return provider.split("CognitoSignIn:")[-1]

    # Fallback for IAM-only contexts
    return identity.get("cognitoIdentityId")


def _get_table():
    table_name = os.environ.get("CLOTHES_TABLE_NAME")
    if not table_name:
        raise RuntimeError("CLOTHES_TABLE_NAME is not set")
    return boto3.resource("dynamodb").Table(table_name)


def _get_clothes_id_from_event(event) -> Optional[str]:
    path_params = event.get("pathParameters") or {}
    proxy = path_params.get("proxy")
    if not proxy:
        return None

    # supports /clothes/{id} via {proxy+}
    proxy = proxy.strip("/")
    if proxy == "":
        return None
    if "/" in proxy:
        return None
    return proxy


def _category_color(category: Optional[str], color: Optional[str]) -> Optional[str]:
    if not category or not color:
        return None
    return f"{category}#{color}"


def _handle_get_list(event, user_id: str):
    table = _get_table()
    q = event.get("queryStringParameters") or {}
    category = q.get("category")
    color = q.get("color")
    category_color = q.get("categoryColor") or _category_color(category, color)

    try:
        if category_color:
            gsi_name = os.environ.get("CLOTHES_GSI_NAME", "byCategoryAndColor")
            resp = table.query(
                IndexName=gsi_name,
                KeyConditionExpression=Key("userId").eq(user_id) & Key("categoryColor").eq(category_color),
            )
        else:
            resp = table.query(
                KeyConditionExpression=Key("userId").eq(user_id),
            )
    except ClientError as e:
        return _response(500, {"ok": False, "error": str(e)})

    items = resp.get("Items") or []
    return _response(200, {"ok": True, "items": items})


def _handle_get_one(user_id: str, clothes_id: str):
    table = _get_table()
    try:
        resp = table.get_item(Key={"userId": user_id, "clothesId": clothes_id})
    except ClientError as e:
        return _response(500, {"ok": False, "error": str(e)})

    item = resp.get("Item")
    if not item:
        return _response(404, {"ok": False, "error": "Not found"})
    return _response(200, {"ok": True, "item": item})


def _handle_post(event, user_id: str):
    table = _get_table()
    payload = _parse_json_body(event)

    category = payload.get("category")
    color = payload.get("color")
    if not category or not color:
        return _response(400, {"ok": False, "error": "category and color are required"})

    clothes_id = str(uuid.uuid4())

    created_at = _now_epoch_seconds()
    updated_at = created_at

    # Backward-compatible: accept imageKey but store in imageUrl.
    image_url = payload.get("imageUrl")
    if image_url is None:
        image_url = payload.get("imageKey")

    season_value = payload.get("season")
    season_set = None
    if isinstance(season_value, list):
        season_set = {str(x) for x in season_value if str(x).strip()}
        if len(season_set) == 0:
            season_set = None

    item = {
        "userId": user_id,
        "clothesId": clothes_id,
        "category": category,
        "subCategory": payload.get("subCategory"),
        "color": color,
        "sleeveLength": payload.get("sleeveLength"),
        "hemLength": payload.get("hemLength"),
        "season": season_set,
        "scene": payload.get("scene"),
        "categoryColor": _category_color(category, color),
        "imageUrl": image_url,
        "name": payload.get("name"),
        "notes": payload.get("notes"),
        "createdAt": created_at,
        "updatedAt": updated_at,
    }
    item = {k: v for k, v in item.items() if v is not None}

    try:
        table.put_item(Item=item, ConditionExpression="attribute_not_exists(clothesId)")
    except ClientError as e:
        return _response(500, {"ok": False, "error": str(e)})

    return _response(201, {"ok": True, "item": item})


def _handle_put(event, user_id: str, clothes_id: str):
    table = _get_table()
    payload = _parse_json_body(event)
    if not isinstance(payload, dict):
        return _response(400, {"ok": False, "error": "Invalid body"})

    # Backward-compatible: accept imageKey but store in imageUrl.
    if "imageKey" in payload and "imageUrl" not in payload:
        payload["imageUrl"] = payload.get("imageKey")

    allowed = {
        "category",
        "subCategory",
        "color",
        "sleeveLength",
        "hemLength",
        "season",
        "scene",
        "imageUrl",
        "name",
        "notes",
    }
    updates = {k: v for k, v in payload.items() if k in allowed}
    if not updates:
        return _response(400, {"ok": False, "error": "No updatable fields"})

    if "season" in updates:
        season_value = updates.get("season")
        if isinstance(season_value, list):
            season_set = {str(x) for x in season_value if str(x).strip()}
            updates["season"] = season_set if len(season_set) > 0 else None
        elif season_value is None:
            updates["season"] = None
        else:
            return _response(400, {"ok": False, "error": "season must be a list of strings"})

    # If category/color changes, keep categoryColor consistent
    category = updates.get("category")
    color = updates.get("color")
    if category is not None or color is not None:
        # Need current values if only one of them is provided
        current_resp = table.get_item(Key={"userId": user_id, "clothesId": clothes_id})
        current = current_resp.get("Item")
        if not current:
            return _response(404, {"ok": False, "error": "Not found"})
        category_final = category if category is not None else current.get("category")
        color_final = color if color is not None else current.get("color")
        updates["categoryColor"] = _category_color(category_final, color_final)

    updates["updatedAt"] = _now_epoch_seconds()

    # Remove explicit null updates to avoid ValidationException in UpdateExpression.
    updates = {k: v for k, v in updates.items() if v is not None}
    if not updates:
        return _response(400, {"ok": False, "error": "No updatable fields"})

    expr_parts = []
    expr_names = {}
    expr_values = {}
    for i, (k, v) in enumerate(updates.items()):
        name_key = f"#k{i}"
        value_key = f":v{i}"
        expr_parts.append(f"{name_key} = {value_key}")
        expr_names[name_key] = k
        expr_values[value_key] = v

    update_expr = "SET " + ", ".join(expr_parts)

    try:
        resp = table.update_item(
            Key={"userId": user_id, "clothesId": clothes_id},
            UpdateExpression=update_expr,
            ExpressionAttributeNames=expr_names,
            ExpressionAttributeValues=expr_values,
            ConditionExpression="attribute_exists(userId) AND attribute_exists(clothesId)",
            ReturnValues="ALL_NEW",
        )
    except ClientError as e:
        if e.response.get("Error", {}).get("Code") == "ConditionalCheckFailedException":
            return _response(404, {"ok": False, "error": "Not found"})
        return _response(500, {"ok": False, "error": str(e)})

    return _response(200, {"ok": True, "item": resp.get("Attributes")})


def _handle_delete(user_id: str, clothes_id: str):
    table = _get_table()
    try:
        table.delete_item(
            Key={"userId": user_id, "clothesId": clothes_id},
            ConditionExpression="attribute_exists(userId) AND attribute_exists(clothesId)",
        )
    except ClientError as e:
        if e.response.get("Error", {}).get("Code") == "ConditionalCheckFailedException":
            return _response(404, {"ok": False, "error": "Not found"})
        return _response(500, {"ok": False, "error": str(e)})

    return _response(200, {"ok": True})


def handler(event, context):
    try:
        if (event.get("httpMethod") or "").upper() == "OPTIONS":
            return _response(200, {"ok": True})

        user_id = _get_user_id(event)
        if not user_id:
            return _response(401, {"ok": False, "error": "Unauthorized"})

        method = (event.get("httpMethod") or "").upper()
        clothes_id = _get_clothes_id_from_event(event)

        if method == "GET" and clothes_id is None:
            return _handle_get_list(event, user_id)
        if method == "POST" and clothes_id is None:
            return _handle_post(event, user_id)
        if method == "GET" and clothes_id is not None:
            return _handle_get_one(user_id, clothes_id)
        if method in ("PUT", "PATCH") and clothes_id is not None:
            return _handle_put(event, user_id, clothes_id)
        if method == "DELETE" and clothes_id is not None:
            return _handle_delete(user_id, clothes_id)

        return _response(404, {"ok": False, "error": "Not found"})
    except ValueError as e:
        return _response(400, {"ok": False, "error": str(e)})
    except Exception as e:
        # Log full traceback for debugging.
        print("Unhandled error:", str(e))
        print(traceback.format_exc())

        # In non-prod, return the exception message to speed up diagnosis.
        env = (os.environ.get("ENV") or "").lower()
        if env in ("", "none", "dev", "development", "test", "staging"):
            return _response(500, {"ok": False, "error": f"{type(e).__name__}: {str(e)}"})

        return _response(500, {"ok": False, "error": "Internal server error"})