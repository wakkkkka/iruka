import base64
import mimetypes


def load_image_as_base64(image_path):
    """
    imgフォルダ内の画像を読み込み、
    (image_base64, mime_type) を返す
    """

    # MIMEタイプを自動判定
    mime_type, _ = mimetypes.guess_type(image_path)

    if mime_type is None:
        raise ValueError("MIMEタイプを判定できません")

    # バイナリ読み込み
    with open(image_path, "rb") as f:
        image_bytes = f.read()

    # Base64変換
    image_base64 = base64.b64encode(image_bytes).decode("utf-8")

    return image_base64, mime_type
