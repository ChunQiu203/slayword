import json
import os
import urllib.request
import time
from pathlib import Path

BASE_URL = "https://apihub.agnes-ai.com"
IMAGE_MODEL = "agnes-image-2.1-flash"
OUTPUT_DIR = Path(r"C:\Users\haoch\Desktop\大三\dasanxia\smart_mobile\111111\slayword\external\sprites\cards")

# 统一风格prompt，只改颜色主题
BASE_STYLE = (
    "pixel art game card frame template, 16-bit retro style, "
    "circular energy cost slot in top-left corner with gold rim, empty inside, "
    "large dark rectangular window in center for artwork, completely black inside, "
    "rectangular box at bottom with gold trim border for description, completely empty inside, "
    "clean sharp pixel edges, game UI asset, "
    "no text no words no letters no numbers no symbols, empty clean template, "
    "portrait orientation"
)

# 四种颜色主题
COLOR_THEMES = {
    "frame_red": "red fire lava stone texture border, volcanic battle theme, dark red orange gradient background",
    "frame_green": "green nature forest stone texture border, earth magic theme, dark green gradient background",  
    "frame_blue": "blue ice crystal stone texture border, cosmic astrology theme, dark blue purple gradient background",
    "frame_purple": "purple dark magic stone texture border, curse void theme, dark purple gradient background",
}

api_key = os.environ.get("AGNES_API_KEY") or os.environ.get("AGNES_API_TOKEN")

for name, color_theme in COLOR_THEMES.items():
    output_path = OUTPUT_DIR / f"{name}.png"
    
    # 跳过已存在的
    if output_path.exists():
        print(f"SKIP: {name} already exists")
        continue
    
    prompt = f"{color_theme}, {BASE_STYLE}"
    print(f"Generating {name}...")
    print(f"  Prompt: {prompt[:80]}...")
    
    payload = json.dumps({
        "model": IMAGE_MODEL,
        "prompt": prompt,
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
    
    try:
        with urllib.request.urlopen(req, timeout=120) as resp:
            result = json.loads(resp.read().decode("utf-8"))
            if "data" in result and len(result["data"]) > 0:
                url = result["data"][0].get("url", "")
                if url:
                    urllib.request.urlretrieve(url, str(output_path))
                    print(f"SUCCESS: {name} saved")
                else:
                    print(f"FAILED: {name} - no URL")
            else:
                print(f"FAILED: {name} - no data")
    except Exception as e:
        print(f"ERROR: {name} - {e}")
    
    time.sleep(2)

print("=" * 60)
print("Done! All frames generated.")
