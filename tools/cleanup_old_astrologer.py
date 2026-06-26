# -*- coding: utf-8 -*-
"""Clean up old Astrologer card/artifact files that conflict with the redesign."""
import os, json, shutil

PROJECT = r"D:\code\slaytheword\slayword"
CARDS = os.path.join(PROJECT, "external", "data", "cards")
ARTIFACTS = os.path.join(PROJECT, "external", "data", "artifacts")

# All new card object_ids created by the redesign generator
NEW_CARD_IDS = {
    "card_astrology_stellar_strike", "card_astrology_stellar_guard",
    "card_astrology_place_saturn", "card_astrology_place_mercury",
    "card_astrology_read_heavens", "card_astrology_destined_strike",
    "card_astrology_mars_warrior", "card_astrology_venus_lover",
    "card_astrology_jupiter_king", "card_astrology_saturn_teacher",
    "card_astrology_uranus_awakener", "card_astrology_neptune_dreamer",
    "card_astrology_pluto_judge", "card_astrology_binary_star",
    "card_astrology_celestial_alignment", "card_astrology_conjunction",
    "card_astrology_opposition", "card_astrology_grand_trine",
    "card_astrology_stellium", "card_astrology_retrograde",
    "card_astrology_aspect", "card_astrology_cosmic_mirror",
    "card_astrology_star_swarm", "card_astrology_astral_projection",
    "card_astrology_forced_eclipse", "card_astrology_supernova",
    "card_astrology_nova", "card_astrology_starburst",
    "card_astrology_cosmic_rebirth", "card_astrology_heat_death",
    "card_astrology_singularity", "card_astrology_constellation_shift",
    "card_astrology_prophecy", "card_astrology_fates_thread",
    "card_astrology_weave_destiny", "card_astrology_predetermined_outcome",
    "card_astrology_omen", "card_astrology_astral_forecast",
    "card_astrology_rewrite_fate", "card_astrology_inertia",
    "card_astrology_accelerate", "card_astrology_starfall",
    "card_astrology_moonshield", "card_astrology_solar_flare",
    "card_astrology_lunar_tide", "card_astrology_meteor_shower",
    "card_astrology_cosmic_ray", "card_astrology_gravity_well",
    "card_astrology_event_horizon", "card_astrology_zodiac_cycle",
    "card_astrology_dark_matter", "card_astrology_celestial_shield",
    "card_astrology_astral_strike", "card_astrology_stardust",
    "card_astrology_fixed_star", "card_astrology_retrograde_motion",
    "card_astrology_grand_cross", "card_astrology_stellar_nursery",
    "card_astrology_twin_destiny", "card_astrology_cosmic_inflation",
    "card_astrology_dark_nebula", "card_astrology_astral_resonance",
    "card_astrology_quick_read", "card_astrology_orbital_strike",
    "card_astrology_dusk_barrier", "card_astrology_stargazer",
    "card_astrology_bad_omen",
}

# All new artifact object_ids
NEW_ARTIFACT_IDS = {
    "artifact_brass_astrolabe", "artifact_star_map",
    "artifact_lens_of_clarity", "artifact_mercury_quill",
    "artifact_comet_shard", "artifact_lunar_calendar",
    "artifact_jupiter_favor", "artifact_constellation_globe",
    "artifact_eclipse_prism", "artifact_saturn_ring",
    "artifact_cosmic_clock", "artifact_nebula_gem",
    "artifact_dark_star", "artifact_zodiac_codex",
    "artifact_heliocentric_model", "artifact_telescope_of_fate",
    "artifact_orrery_of_worlds",
}

# Clean up old cards
backup_dir = os.path.join(PROJECT, "external", "data", "_old_astrologer_backup")
os.makedirs(backup_dir, exist_ok=True)

deleted_cards = 0
for fname in os.listdir(CARDS):
    if not fname.startswith("card_astrology_") or not fname.endswith(".json"):
        continue
    fpath = os.path.join(CARDS, fname)
    try:
        with open(fpath, encoding="utf-8") as f:
            data = json.load(f)
        oid = data["properties"]["object_id"]
    except (json.JSONDecodeError, KeyError):
        # Broken or old-format file - definitely remove
        oid = fname.replace(".json", "")
        print(f"  Removing broken file: {fname}")

    if oid not in NEW_CARD_IDS:
        # Move to backup instead of deleting permanently
        shutil.move(fpath, os.path.join(backup_dir, fname))
        deleted_cards += 1
        print(f"  Moved old card: {fname} ({oid})")

print(f"Cleaned up {deleted_cards} old card files -> _old_astrologer_backup/")

# Clean up old blue artifacts that conflict with new design
old_blue_artifacts = [
    "artifact_celestial_compass", "artifact_starstone_ring",
    "artifact_lunar_amulet", "artifact_eclipse_mask",
    "artifact_cosmic_lens", "artifact_boss_blue",
    "artifact_shop_blue",
]
deleted_arts = 0
for aid in old_blue_artifacts:
    fpath = os.path.join(ARTIFACTS, aid + ".json")
    if os.path.exists(fpath):
        shutil.move(fpath, os.path.join(backup_dir, aid + ".json"))
        deleted_arts += 1
        print(f"  Moved old artifact: {aid}.json")

print(f"Cleaned up {deleted_arts} old artifact files")
print("\nDone! Old files moved to external/data/_old_astrologer_backup/")
