import json
import os
import traceback
import base64
import uuid
import re
from decimal import Decimal
from datetime import datetime, timezone, timedelta
from typing import Any, Dict, List, Optional, Union
from urllib import request as urllib_request
from urllib.error import URLError, HTTPError

import boto3
from botocore.exceptions import ClientError
from boto3.dynamodb.conditions import Key


_GEMINI_API_KEY_CACHE: Optional[str] = None


_DEFAULT_HEADERS = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token,X-Amz-User-Agent",
    "Access-Control-Allow-Methods": "DELETE,GET,HEAD,OPTIONS,PATCH,POST,PUT",
    "Content-Type": "application/json",
}


_GEMINI_MASTER_PROMPT = """
あなたはファッション専門の画像解析AIです。
送られた自撮り写真から「トップス」、「ボトムス」、「アウター」を特定し、指定されたマスタータグに従ってJSON形式で出力してください。

# 厳守ルール
- 以下のマスタータグは厳守し、以下に記載されていないタグを使用することは絶対にやめてください。
- 検出できなかったアイテムや空のオブジェクト（{}）は、絶対に出力に含めないでください。
- JSON形式以外のテキストは一切含めないでください。
- 出力は純粋なJSONのみとし、Markdownのコードブロック（```json ... ```）は絶対に使用しないでください。


# 厳守するマスタータグ定義
- category: tops, bottoms, outer, dress, shoes
- subCategory: t-shirt, shirt/blouse, knit/sweater, sweatshirt/hoodie, denim/jeans, slacks/pants, skirt, shorts, jacket/coat, cardigan, one-piece, setup, sneakers, leather/pumps, boots, sandals
- color: white, black, gray, brown, beige, blue, navy, green, yellow, orange, red, pink, purple, gold, silver, denim, multi-color
- sleeveLength: short, half, long
- hemLength: short, half, long
- season: spring, summer, fall, winter
- scene: casual, business, feminine, other

# 出力形式 (JSON)
{
    \"detected_items\": [
        {
            \"category\": \"tops\",
            \"subCategory\": \"t-shirt\",
            \"color\": \"white\",
            \"sleeveLength\": \"short\",
            \"season\": [\"spring\",\"summer\"],
            \"scene\": \"casual\"
        }
    ]
}
""".strip()


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


def _get_wearlog_table():
    table_name = os.environ.get("WEARLOG_TABLE_NAME")
    if not table_name:
        raise RuntimeError("WEARLOG_TABLE_NAME is not set")
    return boto3.resource("dynamodb").Table(table_name)


def _get_api_path(event) -> str:
    path = (event.get("path") or "").strip()
    if not path:
        return ""
    # API Gateway includes stage in some fields, but event['path'] is typically stage-less.
    return "/" + path.strip("/")


def _download_image_bytes(*, selfie_url: Optional[str], selfie_key: Optional[str]) -> bytes:
    if selfie_url and selfie_url.strip():
        url = selfie_url.strip()
        try:
            req = urllib_request.Request(url, headers={"User-Agent": "amplify-lambda"})
            with urllib_request.urlopen(req, timeout=20) as resp:
                return resp.read()
        except HTTPError as e:
            raise RuntimeError(f"Failed to fetch selfieUrl: HTTP {e.code}")
        except URLError as e:
            raise RuntimeError(f"Failed to fetch selfieUrl: {e}")

    if selfie_key and selfie_key.strip():
        bucket = (os.environ.get("SELFIE_BUCKET_NAME") or "").strip()
        if not bucket:
            raise RuntimeError("SELFIE_BUCKET_NAME is not set (or pass selfieUrl)")
        s3 = boto3.client("s3")
        try:
            obj = s3.get_object(Bucket=bucket, Key=selfie_key.strip())
            return obj["Body"].read()
        except ClientError as e:
            raise RuntimeError(f"Failed to fetch S3 object: {str(e)}")

    raise ValueError("selfieUrl or selfieKey is required")


def _get_gemini_api_key() -> str:
    """Resolve Gemini API key.

    Priority:
    1) Environment variable GEMINI_API_KEY (useful for local/dev)
    2) SSM Parameter Store SecureString pointed by GEMINI_API_KEY_SSM_PARAM
    """

    global _GEMINI_API_KEY_CACHE
    if _GEMINI_API_KEY_CACHE:
        return _GEMINI_API_KEY_CACHE

    direct = (os.environ.get("GEMINI_API_KEY") or "").strip()
    if direct:
        _GEMINI_API_KEY_CACHE = direct
        return direct

    param_name = (os.environ.get("GEMINI_API_KEY_SSM_PARAM") or "").strip()
    if not param_name:
        raise RuntimeError(
            "GEMINI_API_KEY is not set (and GEMINI_API_KEY_SSM_PARAM is not set). "
            "Set GEMINI_API_KEY for quick testing, or configure SSM parameter name in GEMINI_API_KEY_SSM_PARAM."
        )

    try:
        ssm = boto3.client("ssm")
        resp = ssm.get_parameter(Name=param_name, WithDecryption=True)
        value = (((resp or {}).get("Parameter") or {}).get("Value") or "").strip()
        if not value:
            raise RuntimeError(f"SSM parameter is empty: {param_name}")
        _GEMINI_API_KEY_CACHE = value
        return value
    except ClientError as e:
        raise RuntimeError(f"Failed to read SSM parameter {param_name}: {str(e)}")


def _gemini_detect_items(image_bytes: bytes) -> List[Dict[str, Any]]:
    api_key = _get_gemini_api_key()

    primary_model = (os.environ.get("GEMINI_MODEL") or "gemini-1.5-flash-latest").strip()

    prompt = _GEMINI_MASTER_PROMPT

    body = {
        "contents": [
            {
                "parts": [
                    {
                        "inline_data": {
                            "mime_type": "image/jpeg",
                            "data": base64.b64encode(image_bytes).decode("ascii"),
                        }
                    },
                    {"text": prompt},
                ]
            }
        ]
    }

    def _gemini_generate_content(*, model_name: str) -> str:
        url = (
            f"https://generativelanguage.googleapis.com/v1beta/models/{model_name}:generateContent"
            f"?key={api_key}"
        )
        data = json.dumps(body).encode("utf-8")
        req = urllib_request.Request(
            url,
            data=data,
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        with urllib_request.urlopen(req, timeout=25) as resp:
            return resp.read().decode("utf-8")

    def _gemini_list_models() -> List[Dict[str, Any]]:
        url = f"https://generativelanguage.googleapis.com/v1beta/models?key={api_key}"
        req = urllib_request.Request(url, headers={"Content-Type": "application/json"}, method="GET")
        with urllib_request.urlopen(req, timeout=20) as resp:
            raw = resp.read().decode("utf-8")
        decoded = json.loads(raw)
        models = decoded.get("models")
        if isinstance(models, list):
            return [m for m in models if isinstance(m, dict)]
        return []

    def _supports_generate_content(model_obj: Dict[str, Any]) -> bool:
        methods = model_obj.get("supportedGenerationMethods")
        if not isinstance(methods, list):
            return False
        return any(isinstance(m, str) and m == "generateContent" for m in methods)

    def _pick_fallback_model(models: List[Dict[str, Any]]) -> Optional[str]:
        names = []
        for m in models:
            if not _supports_generate_content(m):
                continue
            name = m.get("name")
            if isinstance(name, str) and name.startswith("models/"):
                names.append(name.replace("models/", "", 1))
            elif isinstance(name, str):
                names.append(name)

        if not names:
            return None

        prefer = [
            "gemini-2.0-flash",
            "gemini-2.0-flash-lite",
            "gemini-1.5-flash-latest",
            "gemini-1.5-flash",
            "gemini-1.5-pro-latest",
            "gemini-1.5-pro",
            "gemini-pro",
        ]
        for p in prefer:
            if p in names:
                return p

        # Otherwise, just pick the first available generateContent-capable model.
        return names[0]

    try:
        raw = _gemini_generate_content(model_name=primary_model)
    except HTTPError as e:
        raw_err = e.read().decode("utf-8") if hasattr(e, "read") else str(e)
        if e.code == 404:
            try:
                models = _gemini_list_models()
                fallback = _pick_fallback_model(models)
                if fallback:
                    raw = _gemini_generate_content(model_name=fallback)
                else:
                    available = []
                    for m in models[:25]:
                        n = m.get("name")
                        if isinstance(n, str):
                            available.append(n)
                    raise RuntimeError(
                        "Gemini model not found and no generateContent-capable models available. "
                        f"Set GEMINI_MODEL to a valid model. Available (sample): {available}"
                    )
            except Exception as inner:
                raise RuntimeError(f"Gemini HTTP 404: {raw_err}\n{type(inner).__name__}: {inner}")
        raise RuntimeError(f"Gemini HTTP {e.code}: {raw_err}")
    except URLError as e:
        raise RuntimeError(f"Gemini request failed: {e}")

    decoded = json.loads(raw)
    text = ""
    try:
        candidates = decoded.get("candidates") or []
        parts = (((candidates[0] or {}).get("content") or {}).get("parts") or [])
        for p in parts:
            if isinstance(p, dict) and isinstance(p.get("text"), str):
                text += p["text"]
    except Exception:
        text = ""

    text = (text or "").strip()
    if not text:
        raise RuntimeError(f"Gemini returned no text: {raw}")

    # Try strict JSON parse
    try:
        parsed = json.loads(text)
    except Exception:
        # Fallback: extract first JSON object-like substring
        start = text.find("{")
        end = text.rfind("}")
        if start >= 0 and end > start:
            parsed = json.loads(text[start : end + 1])
        else:
            raise RuntimeError(f"Gemini output is not JSON: {text[:400]}")

    if not isinstance(parsed, dict):
        return []

    items = parsed.get("detected_items")
    if not isinstance(items, list):
        # backward compatibility for older prompt/schema
        items = parsed.get("items")
    if not isinstance(items, list):
        return []

    normalized: List[Dict[str, Any]] = []
    for it in items:
        if not isinstance(it, dict):
            continue
        category = it.get("category")
        if not isinstance(category, str) or not category.strip():
            continue
        sub = it.get("subCategory")
        color = it.get("color")

        sleeve = it.get("sleeveLength")
        hem = it.get("hemLength")
        scene = it.get("scene")
        season = it.get("season")

        # enforce canonical tags to reduce mismatch (prompt already should do this)
        cat_norm = _norm_category(category)
        col_norm = _norm_color(color) if isinstance(color, str) else None

        out: Dict[str, Any] = {"category": cat_norm or category.strip()}
        if isinstance(sub, str) and sub.strip():
            out["subCategory"] = sub.strip()
        if isinstance(color, str) and color.strip():
            out["color"] = col_norm or color.strip().lower()

        if isinstance(sleeve, str) and sleeve.strip():
            out["sleeveLength"] = _norm_text(sleeve) or sleeve.strip()
        if isinstance(hem, str) and hem.strip():
            out["hemLength"] = _norm_text(hem) or hem.strip()
        if isinstance(scene, str) and scene.strip():
            out["scene"] = _norm_text(scene) or scene.strip()
        if isinstance(season, list):
            cleaned = [
                _norm_text(x) or str(x).strip()
                for x in season
                if str(x).strip()
            ]
            cleaned = [x for x in cleaned if x]
            if cleaned:
                out["season"] = cleaned

        normalized.append(out)
    return normalized


def _current_season_jst() -> str:
    # Simple month-based season for Japan.
    # spring: Mar-May, summer: Jun-Aug, fall: Sep-Nov, winter: Dec-Feb
    jst = timezone(timedelta(hours=9))
    m = datetime.now(jst).month
    if 3 <= m <= 5:
        return "spring"
    if 6 <= m <= 8:
        return "summer"
    if 9 <= m <= 11:
        return "fall"
    return "winter"


def _coerce_season_list(value: Any) -> List[str]:
    if value is None:
        return []
    if isinstance(value, (set, tuple, list)):
        out = []
        for x in value:
            v = _norm_text(x) or str(x).strip()
            if v:
                out.append(v)
        return out
    v = _norm_text(value) or str(value).strip()
    return [v] if v else []


def _score_candidate(detected: Dict[str, Any], item: Dict[str, Any]) -> int:
    """Weighted scoring for matching detected tags to closet items.

    Weights (additive):
    - subCategory: +50 (exact)
    - sleeveLength: +20 (exact)
    - hemLength: +20 (exact)
    - scene: +10 (exact)
    - season: +10 (current season included in item's season)
    """

    score = 0

    det_sub = _norm_text(detected.get("subCategory"))
    det_sleeve = _norm_text(detected.get("sleeveLength"))
    det_hem = _norm_text(detected.get("hemLength"))
    det_scene = _norm_text(detected.get("scene"))

    item_sub = _norm_text(item.get("subCategory"))
    item_sleeve = _norm_text(item.get("sleeveLength"))
    item_hem = _norm_text(item.get("hemLength"))
    item_scene = _norm_text(item.get("scene"))

    if det_sub and item_sub and det_sub == item_sub:
        score += 50

    if det_sleeve and item_sleeve and det_sleeve == item_sleeve:
        score += 20

    if det_hem and item_hem and det_hem == item_hem:
        score += 20

    if det_scene and item_scene and det_scene == item_scene:
        score += 10

    current = _current_season_jst()
    item_seasons = _coerce_season_list(item.get("season"))
    if current in item_seasons:
        score += 10

    return score


def _handle_analyze(event, user_id: str):
    payload = _parse_json_body(event)
    selfie_key = payload.get("selfieKey")
    selfie_url = payload.get("selfieUrl")
    top_k = payload.get("topK")
    if not isinstance(top_k, int) or top_k <= 0 or top_k > 10:
        top_k = 3

    image_bytes = _download_image_bytes(
        selfie_url=selfie_url if isinstance(selfie_url, str) else None,
        selfie_key=selfie_key if isinstance(selfie_key, str) else None,
    )

    detected_items = _gemini_detect_items(image_bytes)
    table = _get_table()
    gsi_name = os.environ.get("CLOTHES_GSI_NAME", "byCategoryAndColor")

    print(
        "Analyze detected_items=",
        detected_items,
    )

    results: List[Dict[str, Any]] = []
    no_match_threshold = 20
    for detected in detected_items:
        category = detected.get("category")
        color = detected.get("color")
        category_color = _category_color(category, color)
        category_color_norm = _category_color_norm(category, color)

        candidates: List[Dict[str, Any]] = []
        try:
            if category_color:
                resp = table.query(
                    IndexName=gsi_name,
                    KeyConditionExpression=Key("userId").eq(user_id)
                    & Key("categoryColor").eq(category_color),
                )
                candidates = resp.get("Items") or []

            # If nothing matched, try normalized key (covers cases like "紺" vs "navy" if stored normalized)
            if not candidates and category_color_norm and category_color_norm != category_color:
                resp = table.query(
                    IndexName=gsi_name,
                    KeyConditionExpression=Key("userId").eq(user_id)
                    & Key("categoryColor").eq(category_color_norm),
                )
                candidates = resp.get("Items") or []

            # Final fallback: query all for user and filter by normalized category/color
            if not candidates:
                resp = table.query(KeyConditionExpression=Key("userId").eq(user_id))
                all_items = resp.get("Items") or []
                det_cat = _norm_category(category)
                det_col = _norm_color(color)
                filtered = []
                for it in all_items:
                    if det_cat and _norm_category(it.get("category")) != det_cat:
                        continue
                    if det_col and _norm_color(it.get("color")) != det_col:
                        # allow category-only match if color mismatch
                        continue
                    filtered.append(it)

                # If still empty and we had a color, relax to category-only.
                if not filtered and det_cat:
                    for it in all_items:
                        if _norm_category(it.get("category")) == det_cat:
                            filtered.append(it)

                candidates = filtered
        except ClientError as e:
            return _response(500, {"ok": False, "error": str(e)})

        print(
            "Analyze match",
            {
                "detected": detected,
                "categoryColor": category_color,
                "categoryColorNorm": category_color_norm,
                "candidatesCount": len(candidates),
            },
        )

        scored = []
        for c in candidates:
            s = _score_candidate(detected, c)
            scored.append((s, c))
        scored.sort(key=lambda t: t[0], reverse=True)

        best_score = scored[0][0] if scored else 0
        needs_register = best_score <= no_match_threshold

        top = []
        for s, c in scored[:top_k]:
            top.append(
                {
                    "clothesId": c.get("clothesId"),
                    "category": c.get("category"),
                    "subCategory": c.get("subCategory"),
                    "color": c.get("color"),
                    "sleeveLength": c.get("sleeveLength"),
                    "hemLength": c.get("hemLength"),
                    "season": c.get("season"),
                    "scene": c.get("scene"),
                    "imageUrl": c.get("imageUrl"),
                    "score": s,
                }
            )

        results.append(
            {
                "detected": detected,
                "candidates": top,
                "bestScore": best_score,
                "needsRegister": needs_register,
            }
        )

    return _response(200, {"ok": True, "results": results})


def _parse_iso_date(value: str) -> str:
    v = (value or "").strip()
    datetime.strptime(v, "%Y-%m-%d")
    return v


def _handle_logs_get(event, user_id: str):
    q = event.get("queryStringParameters") or {}
    from_s = q.get("from")
    to_s = q.get("to")

    # default: last 30 days
    now = datetime.now()
    if not isinstance(from_s, str) or not from_s.strip():
        from_s = (now.replace(hour=0, minute=0, second=0, microsecond=0) - timedelta(days=30)).strftime(
            "%Y-%m-%d"
        )
    if not isinstance(to_s, str) or not to_s.strip():
        to_s = now.strftime("%Y-%m-%d")

    from_s = _parse_iso_date(from_s)
    to_s = _parse_iso_date(to_s)

    start = f"{from_s}#"
    end = f"{to_s}#\uffff"

    table = _get_wearlog_table()
    try:
        resp = table.query(
            KeyConditionExpression=Key("userId").eq(user_id) & Key("logId").between(start, end)
        )
    except ClientError as e:
        return _response(500, {"ok": False, "error": str(e)})

    items = resp.get("Items") or []
    # newest first
    items.sort(key=lambda x: (x.get("date") or "", x.get("logId") or ""), reverse=True)
    return _response(200, {"ok": True, "items": items})


def _handle_logs_post(event, user_id: str):
    payload = _parse_json_body(event)
    date = payload.get("date")
    if not isinstance(date, str) or not date.strip():
        return _response(400, {"ok": False, "error": "date is required"})
    date = _parse_iso_date(date)

    log_id = f"{date}#{uuid.uuid4()}"
    created_at = _now_epoch_seconds()

    selections = payload.get("selections")
    if selections is not None and not isinstance(selections, dict):
        return _response(400, {"ok": False, "error": "selections must be an object"})

    clothes_ids = payload.get("clothesIds")
    if clothes_ids is not None and not isinstance(clothes_ids, list):
        return _response(400, {"ok": False, "error": "clothesIds must be an array"})

    item = {
        "userId": user_id,
        "logId": log_id,
        "date": date,
        "selfieKey": payload.get("selfieKey"),
        "selections": selections,
        "clothesIds": clothes_ids,
        "createdAt": created_at,
    }
    item = {k: v for k, v in item.items() if v is not None}

    table = _get_wearlog_table()
    try:
        table.put_item(Item=item, ConditionExpression="attribute_not_exists(logId)")
    except ClientError as e:
        return _response(500, {"ok": False, "error": str(e)})

    return _response(201, {"ok": True, "item": item})


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


def _norm_text(value: Optional[str]) -> Optional[str]:
    if value is None:
        return None
    if not isinstance(value, str):
        value = str(value)
    v = value.strip().lower()
    if not v:
        return None
    v = re.sub(r"\s+", " ", v)
    return v


def _norm_category(value: Optional[str]) -> Optional[str]:
    v = _norm_text(value)
    if not v:
        return None

    # canonical categories used in this app
    if v in {"tops", "top", "トップス", "シャツ", "t-shirt", "tshirt", "tee", "shirt", "blouse"}:
        return "tops"
    if v in {"bottoms", "bottom", "ボトムス", "パンツ", "ズボン", "skirt", "スカート"}:
        return "bottoms"
    if v in {"outer", "アウター", "コート", "ジャケット", "coat", "jacket"}:
        return "outer"
    if v in {"shoes", "shoe", "シューズ", "靴", "sneakers", "sneaker"}:
        return "shoes"

    # heuristic contains
    if "トップ" in v or "シャツ" in v or "tshirt" in v or "t-shirt" in v or "shirt" in v:
        return "tops"
    if "ボトム" in v or "パンツ" in v or "ズボン" in v or "skirt" in v:
        return "bottoms"
    if "アウター" in v or "コート" in v or "ジャケット" in v or "outer" in v:
        return "outer"
    if "靴" in v or "シュー" in v or "shoe" in v or "sneaker" in v:
        return "shoes"

    return v


def _norm_color(value: Optional[str]) -> Optional[str]:
    v = _norm_text(value)
    if not v:
        return None

    # normalize common variants
    if "navy" in v or "紺" in v:
        return "navy"
    if "black" in v or "黒" in v:
        return "black"
    if "white" in v or "白" in v:
        return "white"
    if "gray" in v or "grey" in v or "グレー" in v or "灰" in v:
        return "gray"
    if "beige" in v or "ベージュ" in v:
        return "beige"
    if "brown" in v or "茶" in v:
        return "brown"
    if "blue" in v or "青" in v:
        return "blue"
    if "red" in v or "赤" in v:
        return "red"
    if "green" in v or "緑" in v:
        return "green"

    return v


def _category_color_norm(category: Optional[str], color: Optional[str]) -> Optional[str]:
    c = _norm_category(category)
    col = _norm_color(color)
    if not c or not col:
        return None
    return f"{c}#{col}"


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
        path = _get_api_path(event)

        if path.endswith("/analyze"):
            if method != "POST":
                return _response(405, {"ok": False, "error": "Method not allowed"})
            return _handle_analyze(event, user_id)

        if path.endswith("/logs"):
            if method == "GET":
                return _handle_logs_get(event, user_id)
            if method == "POST":
                return _handle_logs_post(event, user_id)
            return _response(405, {"ok": False, "error": "Method not allowed"})

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
