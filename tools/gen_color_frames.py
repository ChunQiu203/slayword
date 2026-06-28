import json
import os
import urllib.request
from pathlib import Path

BASE_URL = "https://apihub.agnes-ai.com"
IMAGE_MODEL = "agnes-image-2.1-flash"
OUTPUT_DIR = Path(r"C:\Users\haoch\Desktop\大三\dasanxia\smart_mobile\111111\slayword\external\sprites\cards")

# 不同卡牌类型的边框prompt
FRAME_PROMPTS = {
    "frame_red": (
        "pixel art game card frame template, 16-bit retro style, "
        "red fire stone texture border with battle theme, "
        "dark red orange gradient background, "
        "circular energy cost slot in top-left corner with gold rim, empty inside, "
        "large dark rectangular window in center, completely black inside, "
        "rectangular box at bottom with gold trim border, completely empty inside, "
        "clean sharp pixel edges, game UI asset, "
        "no text no words no letters no numbers, empty template"
    ),
    "frame_green": (
        "pixel art game card frame template, 16-bit retro style, "
        "green nature stone texture border with forest theme, "
        "dark green gradient background, "
        "circular energy cost slot in top-left corner with gold rim, empty inside, "
        "large dark rectangular window in center, completely black inside, "
        "rectangular box at bottom with gold trim border, completely empty inside, "
        "clean sharp pixel edges, game UI asset, "
        "no text no words no letters no numbers, empty template"
    ),
    "frame_purple": (
        "pixel art game card frame template, 16-bit retro style, "
        "purple dark magic stone texture border with curse theme, "
        "dark purple gradient background, "
        "circular energy cost slot in top-left corner with gold rim, empty inside, "
        "large dark rectangular window in center, completely black inside, "
        "rectangular box at bottom with gold trim border, completely empty inside, "
        "clean sharp pixel edges, game UI asset, "
        "no text no words no letters no numbers, empty template"
    ),
}

api_key = os.environ.get("AGNES_API_KEY") or os.environ.get("AGNES_API_TOKEN")

for name, prompt in FRAME_PROMPTS.items():
    output_path = OUTPUT_DIR / f"{name}.png"
    
    # 跳过已存在的
    if output_path.exists():
        print(f"SKIP: {name} already exists")
        continue
    
    print(f"Generating {name}...")
    
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
                    print(f"SUCCESS: {name}")
                else:
                    print(f"FAILED: {name} - no URL")
            else:
                print(f"FAILED: {name} - no data")
    except Exception as e:
        print(f"ERROR: {name} - {e}")
    
    # 避免API限流
    import time
    time.sleep(2)

print("Done!")
