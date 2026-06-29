#!/usr/bin/env python3
"""Generate card frame template for the Astrologer class"""

import json
import os
import sys
import time
import urllib.request
import urllib.error
from pathlib import Path

BASE_URL = "https://apihub.agnes-ai.com"
IMAGE_MODEL = "agnes-image-2.1-flash"
PROJECT_ROOT = Path(__file__).resolve().parent.parent
OUTPUT_DIR = PROJECT_ROOT / "external" / "sprites" / "cards"

FRAME_PROMPT = (
    "pixel art game card frame template, 16-bit retro style, "
    "blue stone texture border with cosmic astrology theme, "
    "dark blue purple gradient background, "
    "Slay the Spire card frame design, "
    "circular energy cost slot in top-left corner (empty dark circle), "
    "horizontal banner area at top for card name (dark semi-transparent), "
    "large central rectangular area for card artwork (very dark, almost black), "
    "small horizontal label bar in middle for card type, "
    "text description area at bottom with dark background, "
    "clean sharp pixel edges, game UI asset, "
    "no text no characters no creatures, "
    "portrait orientation 500x680 pixels, "
    "complete self-contained frame template"
)


def get_api_key():
    for name in ("AGNES_API_KEY", "AGNES_API_TOKEN", "APIHUB_AGNES_API_KEY"):
        value = os.environ.get(name)
        if value:
            return value
    raise SystemExit("Missing API key.")


def generate_image(prompt, api_key):
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
                item = result["data"][0]
                return item.get("url") or item.get("b64_json") or ""
            return ""
    except Exception as e:
        print(f"  Error: {e}")
        return ""


def download_image(url, save_path):
    try:
        urllib.request.urlretrieve(url, str(save_path))
        return True
    except Exception as e:
        print(f"  Download error: {e}")
        return False


def main():
    api_key = get_api_key()
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    output_path = OUTPUT_DIR / "frame_blue.png"

    print(f"Generating card frame template...")
    print(f"Output: {output_path}")

    url = generate_image(FRAME_PROMPT, api_key)

    if url:
        if download_image(url, output_path):
            print(f"SUCCESS: Saved to {output_path}")
        else:
            print("FAILED: Could not download")
            sys.exit(1)
    else:
        print("FAILED: No URL returned")
        sys.exit(1)


if __name__ == "__main__":
    main()
