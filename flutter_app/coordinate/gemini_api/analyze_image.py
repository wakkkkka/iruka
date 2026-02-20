import base64
from google.genai import types

def analyze_image(image_base64: str, mime_type: str, prompt: str, client):

    # Base64 → バイトに戻す
    image_bytes = base64.b64decode(image_base64)
    response = client.models.generate_content(
        model="gemini-3-flash-preview",
        contents=[
            types.Part.from_bytes(
                data=image_bytes,
                mime_type=mime_type
            ),
            prompt
        ]
    )

    return response
