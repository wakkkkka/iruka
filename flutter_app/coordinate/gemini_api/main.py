import os
import time
from pathlib import Path
from google import genai
from dotenv import load_dotenv

from image_loader import load_image_as_base64
from analyze_image import analyze_image

# Load environment variables from .env file
script_dir = Path(__file__).parent
load_dotenv(script_dir / ".env")

# response = client.models.generate_content(
#     model="gemini-3-flash-preview", contents="Explain how AI works in a few words"
# )
# print(response.text)

# The client gets the API key from the environment variable `GEMINI_API_KEY`.
client = genai.Client(api_key=os.getenv("GEMINI_API_KEY"))

prompt = """
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
  "detected_items": [
    {
      "category": "tops",
      "subCategory": "t-shirt",
      "color": "white",
      "sleeveLength": "short",
      "season": ["spring","summer"],
      "scene": "casual"
    },
    ...
  ]
}
"""
image_base64, mime_type = load_image_as_base64(str(script_dir / "img/fashion1.jpg"))

# print(mime_type)
# print(image_base64[:100])  # 長いので一部だけ表示

# 試行回数
n = 1

# 出力にかかった時間
timings = []

for i in range(n):
    start_time = time.perf_counter()
    response = analyze_image(image_base64, mime_type, prompt, client)
    elapsed = time.perf_counter() - start_time
    timings.append(elapsed)
    print(response.text)

max_time = max(timings) if timings else 0.0
min_time = min(timings) if timings else 0.0
avg_time = (sum(timings) / len(timings)) if timings else 0.0
print(f"max request time: {max_time:.3f}s")
print(f"min request time: {min_time:.3f}s")
print(f"avg request time: {avg_time:.3f}s")
