import json
import os
import urllib.request
from pathlib import Path

BASE_URL = "https://apihub.agnes-ai.com"
IMAGE_MODEL = "agnes-image-2.1-flash"
OUTPUT_DIR = Path(r"C:\Users\haoch\Desktop\大三\dasanxia\smart_mobile\111111\slayword\external\sprites\cards")

# Ultra clean frame prompt
CLEAN_FRAME_PROMPT = (
    "pixel art game card frame template, 16-bit retro style, "
    "blue stone texture border with cosmic astrology theme, "
    "dark blue purple gradient background, "
    "circular slot in top-left corner with gold rim, empty inside, "
    "large dark rectangular window in center, completely black inside, "
    "rectangular box at bottom with gold trim border, completely empty inside, "
    "clean sharp pixel edges, game UI asset, "
    "no text no words no letters no numbers no symbols no characters, "
    "empty template, blank spaces, pure frame structure only"
)

api_key = os.environ.get("AGNES_API_KEY") or os.environ.get("AGNES_API_TOKEN")

payload = json.dumps({
    "model": IMAGE_MODEL,
    "prompt": CLEAN_FRAME_PROMPT,
    "size": "1024x1536",
    "extra_body": {"response_format": "url"},
}).encode("utf-8")

req = urllib.request.Request(
    f"{BASE_URL}/v1/images/generations",
    data=payload,
    method="POST",
    headers={
        "Authorization": f"Bearer {api_key}",
        "Content-Type": "application/json",
    },
)

print("Generating ultra clean frame template...")
with urllib.request.urlopen(req, timeout=120) as resp:
    result = json.loads(resp.read().decode("utf-8"))
    if "data" in result and len(result["data"]) > 0:
        url = result["data"][0].get("url", "")
        if url:
            output_path = OUTPUT_DIR / "frame_blue_v2.png"
            urllib.request.urlretrieve(url, str(output_path))
            print(f"SUCCESS: Saved to {output_path}")
        else:
            print("FAILED: No URL")
    else:
        print("FAILED: No data")
