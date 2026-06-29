#!/usr/bin/env python3
"""批量生成占星师卡牌像素风格插画"""

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
CARDS_DIR = PROJECT_ROOT / "external" / "data" / "cards"
OUTPUT_DIR = PROJECT_ROOT / "external" / "sprites" / "cards" / "generated"

# 卡牌主题映射 - 根据卡牌名称和类型生成对应的英文prompt主题
CARD_THEMES = {
    # === 攻击牌 (ATTACK) ===
    "stellar_strike": "A glowing blue energy sword slashing through space, leaving a trail of stardust",
    "destined_strike": "A burst of golden cosmic energy with threads of fate weaving through stars",
    "solar_flare": "A massive solar eruption with bright orange and yellow flames",
    "cosmic_ray": "A concentrated beam of purple cosmic energy shooting across space",
    "nova": "A brilliant white star explosion radiating outward in all directions",
    "starfall": "Multiple bright blue meteors raining down from a dark sky",
    "star_swarm": "A swarm of tiny glowing blue stars moving together like a school of fish",
    "supernova": "A massive supernova explosion with expanding shockwaves of color",
    "astral_strike": "A translucent astral blade floating in cosmic energy",
    "opposition": "Two opposing celestial forces colliding in a burst of energy",
    "orbital_strike": "A planet-sized projectile following an orbital trajectory",
    "heat_death": "The universe fading into cold darkness with dying red embers",
    "meteor_shower": "A shower of glowing meteorites streaking across a dark cosmic sky",

    # === 技能牌 (SKILL) ===
    "stellar_guard": "A translucent blue energy shield formed from constellation patterns",
    "place_saturn": "The planet Saturn with its rings glowing in golden light, floating in space",
    "place_mercury": "The small swift planet Mercury with silver streaks of speed",
    "read_heavens": "An ancient star map unfurling with glowing constellation lines",
    "prophecy": "A glowing crystal ball showing swirling cosmic visions",
    "quick_read": "An open magical book with pages flipping rapidly, stars flying out",
    "retrograde": "A planetary symbol spinning backward with reverse energy trails",
    "cosmic_mirror": "A reflective cosmic portal showing mirrored starfield",
    "dark_matter": "An invisible swirling vortex distorting the space around it",
    "conjunction": "Two bright stars merging together in a brilliant embrace",
    "aspect": "Geometric angular lines connecting celestial bodies in sacred geometry",
    "celestial_alignment": "Five planets perfectly aligned in a straight line glowing together",
    "gravity_well": "A deep purple gravitational vortex pulling in surrounding stars and debris",
    "lunar_tide": "A crescent moon above cosmic waves of silver energy",
    "cosmic_rebirth": "A phoenix made of stardust rising from cosmic ashes",
    "singularity": "An infinitely dense point of light warping space around it",
    "rewrite_fate": "Golden threads of destiny being woven into a new pattern",
    "stellium": "Multiple stars converging into a powerful bright cluster",
    "forced_eclipse": "A dark celestial body blocking out a bright star, creating a corona",
    "predetermined_outcome": "A cosmic clock with golden hands pointing to a fixed moment",
    "astral_projection": "A translucent spirit form floating above a sleeping body among stars",
    "celestial_shield": "A large shield decorated with constellation patterns glowing blue",
    "dusk_barrier": "A barrier of purple and orange twilight energy blocking the way",
    "constellation_shift": "A constellation pattern transforming and rearranging its stars",
    "grand_trine": "Three bright stars connected by golden lines forming a perfect triangle",
    "accelerate": "Speed lines and motion blur showing rapid cosmic movement",
    "inertia": "A celestial object maintaining its trajectory with trailing energy",
    "omen": "A dark mysterious eye symbol glowing with purple ominous light",
    "bad_omen": "A cracked and broken fortune symbol with dark energy leaking out",
    "astral_forecast": "A cosmic weather map showing incoming stellar storms",
    "fates_thread": "Delicate glowing threads connecting different points in spacetime",
    "stardust": "Sparkling particles of cosmic dust floating in a beam of light",
    "starburst": "A radial burst of bright starlight expanding outward",
    "stargazer": "A silhouette of a person looking through a telescope at a vast starfield",

    # === 能力牌 (POWER) ===
    "binary_star": "Two bright stars orbiting each other in a gravitational dance",
    "fixed_star": "A single bright unwavering star with stable golden光芒",
    "saturn_teacher": "Saturn surrounded by a wise golden aura with ancient symbols",
    "mars_warrior": "Mars with red battle armor and火星 energy radiating outward",
    "jupiter_king": "Jupiter as a massive king planet with a golden crown of storms",
    "venus_lover": "Venus surrounded by pink and green loving energy with heart shapes",
    "neptune_dreamer": "Neptune in dreamy blue-purple haze with watery ethereal waves",
    "uranus_awakener": "Uranus with electric blue lightning bolts awakening the sky",
    "pluto_judge": "Pluto holding cosmic scales of judgment in dark purple energy",
    "astral_resonance": "Concentric rings of astral energy vibrating in perfect harmony",
    "cosmic_inflation": "An expanding bubble of universe energy pushing outward",
    "dark_nebula": "A dark cloud of cosmic dust obscuring stars behind it",
    "event_horizon": "The glowing edge of a black hole with light bending around it",
    "grand_cross": "Four celestial bodies forming a perfect cross with energy connecting them",
    "retrograde_motion": "A planet tracing a loop-de-loop path in its orbit",
    "stellar_nursery": "A colorful nebula with bright young stars being born inside",
    "twin_destiny": "Two identical star figures connected by cosmic destiny bonds",
    "zodiac_cycle": "A circular wheel of zodiac symbols rotating with cosmic energy",
}

# 基础风格描述
BASE_STYLE = (
    "pixel art illustration, 16-bit retro game style, "
    "dark cosmic background with scattered stars, "
    "Slay the Spire card art style, "
    "saturated vibrant colors, clear contrast between light and dark, "
    "centered composition, single game asset on dark background, "
    "no text no UI no frame, clean illustration only, "
    "no people no characters no figures no humans no silhouettes, "
    "pure cosmic abstract celestial art"
)

# 卡牌类型修饰词
TYPE_MODIFIERS = {
    0: "energy burst, impact effect, explosive power",
    1: "mystical symbol, magical glow, celestial pattern",
    2: "persistent aura, cosmic resonance, orbital rings",
    4: "dark ominous energy, corrupted glow, cursed symbol",
}

CARD_TYPE_NAMES = {0: "ATTACK", 1: "SKILL", 2: "POWER", 4: "STATUS"}


def get_api_key() -> str:
    for name in ("AGNES_API_KEY", "AGNES_API_TOKEN", "APIHUB_AGNES_API_KEY"):
        value = os.environ.get(name)
        if value:
            return value
    raise SystemExit("Missing API key. Set AGNES_API_KEY, AGNES_API_TOKEN, or APIHUB_AGNES_API_KEY.")


def load_card_data(card_id: str) -> dict:
    json_path = CARDS_DIR / f"{card_id}.json"
    with open(json_path, "r", encoding="utf-8") as f:
        data = json.load(f)
    props = data["properties"]
    return {
        "id": props["object_id"],
        "name": props["card_name"],
        "type": props["card_type"],
        "cost": props["card_energy_cost"],
        "description": props["card_description"],
    }


def build_prompt(card: dict) -> str:
    card_id = card["id"].replace("card_astrology_", "")
    card_type = card["type"]
    card_name = card["name"]

    theme = CARD_THEMES.get(card_id, f"cosmic astrology themed {card_name}")
    type_mod = TYPE_MODIFIERS.get(card_type, "mystical cosmic energy")

    prompt = f"{theme}, {type_mod}, {BASE_STYLE}"
    return prompt


def generate_image(prompt: str, api_key: str) -> str:
    payload = json.dumps({
        "model": IMAGE_MODEL,
        "prompt": prompt,
        "size": "512x512",
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
    except urllib.error.HTTPError as exc:
        detail = exc.read().decode("utf-8", errors="replace")
        print(f"  HTTP {exc.code}: {detail[:200]}")
        return ""
    except Exception as e:
        print(f"  Error: {e}")
        return ""


def download_image(url: str, save_path: Path) -> bool:
    try:
        urllib.request.urlretrieve(url, str(save_path))
        return True
    except Exception as e:
        print(f"  Download error: {e}")
        return False


def main():
    api_key = get_api_key()
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    # 找到所有占星师卡牌
    card_files = sorted(CARDS_DIR.glob("card_astrology_*.json"))
    if not card_files:
        print("No astrology card files found!")
        sys.exit(1)

    print(f"Found {len(card_files)} astrology cards")
    print(f"Output directory: {OUTPUT_DIR}")
    print(f"API: {BASE_URL}/v1/images/generations")
    print(f"Model: {IMAGE_MODEL}")
    print("=" * 60)

    success = 0
    failed = []
    skipped = 0

    for i, card_file in enumerate(card_files):
        card_id = card_file.stem
        output_path = OUTPUT_DIR / f"{card_id}.png"

        # 跳过已存在的图片
        if output_path.exists():
            print(f"[{i+1}/{len(card_files)}] SKIP (exists): {card_id}")
            skipped += 1
            continue

        card = load_card_data(card_id)
        prompt = build_prompt(card)

        print(f"[{i+1}/{len(card_files)}] Generating: {card['name']} ({CARD_TYPE_NAMES.get(card['type'], '?')})")
        print(f"  Prompt: {prompt[:100]}...")

        url = generate_image(prompt, api_key)

        if url:
            if download_image(url, output_path):
                print(f"  Saved: {output_path.name}")
                success += 1
            else:
                failed.append(card_id)
        else:
            print(f"  FAILED: No URL returned")
            failed.append(card_id)

        # 避免API限流
        if i < len(card_files) - 1:
            time.sleep(2)

    print("=" * 60)
    print(f"Results: {success} generated, {skipped} skipped, {len(failed)} failed")
    if failed:
        print(f"Failed cards: {', '.join(failed)}")


if __name__ == "__main__":
    main()
