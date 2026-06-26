# -*- coding: utf-8 -*-
"""Generate all Star Chart (Astrologer) JSON data files."""
import json, os

PROJECT = r"D:\code\slaytheword\slayword"
CARDS = os.path.join(PROJECT, "external", "data", "cards")
ARTIFACTS = os.path.join(PROJECT, "external", "data", "artifacts")
CONSUMABLES = os.path.join(PROJECT, "external", "data", "consumables")
CHARS = os.path.join(PROJECT, "external", "data", "characters")
CUI = os.path.join(PROJECT, "external", "data", "custom_ui")
ART_SCRIPTS = os.path.join(PROJECT, "scripts", "artifacts")
UI_SCRIPTS = os.path.join(PROJECT, "scripts", "ui", "custom")

for d in [CUI]: os.makedirs(d, exist_ok=True)

ATTACK, SKILL, POWER, STATUS, CURSE = 0, 1, 2, 3, 4
BASIC, COMMON, UNCOMMON, RARE, GENERATED = 0, 1, 2, 3, 4
BOSS, SHOP, EVENT = 4, 5, 6

A_ATK = "res://scripts/actions/meta_actions/ActionAttackGenerator.gd"
A_BLK = "res://scripts/actions/ActionBlock.gd"
A_DRW = "res://scripts/actions/meta_actions/ActionDrawGenerator.gd"
A_NRG = "res://scripts/actions/ActionAddEnergy.gd"
A_STA = "res://scripts/actions/status_actions/ActionApplyStatus.gd"
A_PCK = "res://scripts/actions/pick_card_actions/ActionPickCards.gd"
A_DIS = "res://scripts/actions/cardset_actions/ActionDiscardCards.gd"
A_AHD = "res://scripts/actions/cardset_actions/ActionAddCardsToHand.gd"
A_PLA = "res://scripts/actions/star_chart_actions/ActionPlaceStar.gd"
A_CON = "res://scripts/actions/star_chart_actions/ActionConsumeStar.gd"
A_ROT = "res://scripts/actions/star_chart_actions/ActionRotateStars.gd"
A_ECL = "res://scripts/actions/star_chart_actions/ActionEclipse.gd"
A_ALN = "res://scripts/actions/star_chart_actions/ActionTriggerAlignment.gd"

SELF = 1
ALL_EN = 4

def wj(path, data):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        json.dump(data, f, ensure_ascii=False, indent="\t")

# ── Step 1: Artifact script ────────────────────────────────────────────
with open(os.path.join(ART_SCRIPTS, "ArtifactBrassAstrolabe.gd"), "w", encoding="utf-8", newline="\n") as f:
    f.write("""extends BaseArtifact
## The Astrologer's starting relic. Places 2 Stars at combat start.
## At end of each turn, rotates all Stars clockwise and checks for Eclipse.

func connect_signals() -> void:
\tsuper()
\tSignals.combat_started.connect(_on_combat_started_astro)

func _on_combat_started_astro(_event_id: String) -> void:
\tvar rng := RandomNumberGenerator.new()
\trng.randomize()
\tfor _i in range(2):
\t\tStarChartHelper.place_star(rng.randi_range(0, 5))

func _on_player_turn_ended() -> void:
\tsuper()
\tStarChartHelper.rotate_stars()
\tif StarChartHelper.check_eclipse():
\t\tStarChartHelper.trigger_eclipse()
""")
print("[1/6] ArtifactBrassAstrolabe.gd")

# ── Step 2: StarChartUI.gd ────────────────────────────────────────────
with open(os.path.join(UI_SCRIPTS, "StarChartUI.gd"), "w", encoding="utf-8", newline="\n") as f:
    f.write("""extends BaseCustomUI
## Renders the Astrologer's Star Chart - 6 Houses with star counts.

const HOUSE_NAMES := ["Dawn", "Noon", "Dusk", "Night", "Wisdom", "Fate"]
const HOUSE_COLORS := [
\tColor(1.0, 0.85, 0.4), Color(1.0, 0.4, 0.2), Color(0.7, 0.4, 0.8),
\tColor(0.2, 0.3, 0.9), Color(0.3, 0.9, 0.7), Color(0.9, 0.2, 0.9),
]
var _star_labels: Array[Label] = []

func init(custom_ui_object_id: String, _parent_combatant: BaseCombatant) -> void:
\tsuper(custom_ui_object_id, _parent_combatant)
\t_build_ui()
\tSignals.star_placed.connect(_refresh)
\tSignals.star_consumed.connect(_refresh2)
\tSignals.stars_rotated.connect(_refresh0)
\tSignals.eclipse_triggered.connect(_refresh0)
\t_refresh()

func _build_ui() -> void:
\tvar vb := VBoxContainer.new()
\tvb.set_anchors_preset(Control.PRESET_TOP_RIGHT)
\tvb.position = Vector2(-160, 60)
\tadd_child(vb)
\tvar tl := Label.new()
\ttl.text = "Star Chart"
\ttl.add_theme_color_override("font_color", Color(0.9, 0.85, 0.5))
\ttl.add_theme_font_size_override("font_size", 14)
\tvb.add_child(tl)
\tvar grid := GridContainer.new()
\tgrid.columns = 2
\tvb.add_child(grid)
\tfor i in range(6):
\t\tvar nl := Label.new()
\t\tnl.text = HOUSE_NAMES[i]
\t\tnl.add_theme_color_override("font_color", HOUSE_COLORS[i])
\t\tnl.add_theme_font_size_override("font_size", 11)
\t\tgrid.add_child(nl)
\t\tvar cl := Label.new()
\t\tcl.text = "0"
\t\tcl.add_theme_font_size_override("font_size", 13)
\t\tgrid.add_child(cl)
\t\t_star_labels.append(cl)

func _refresh(_h: int = -1) -> void:
\tvar chart = StarChartHelper.get_star_chart()
\tfor i in range(6):
\t\tif i < _star_labels.size():
\t\t\t_star_labels[i].text = str(int(chart[i]))
\t\t\t_star_labels[i].add_theme_color_override("font_color",
\t\t\t\tColor.YELLOW if int(chart[i]) >= 2 else Color.WHITE)

func _refresh2(_h: int, _c: int) -> void: _refresh()
func _refresh0(_t: int = 0) -> void: _refresh()
""")
print("[2/6] StarChartUI.gd")

# ── Step 3: Cards ─────────────────────────────────────────────────────
cards_data = []
def mkcard(oid, name, cost, ctype, rarity, desc, vals, actions, **kw):
    p = {
        "object_id": oid, "card_name": name, "card_color_id": "color_blue",
        "card_description": desc, "card_energy_cost": cost, "card_type": ctype,
        "card_rarity": rarity, "card_requires_target": (ctype == ATTACK),
        "card_appears_in_card_packs": (rarity not in [BASIC, GENERATED]),
        "card_is_playable": kw.get("playable", True),
        "card_exhausts": kw.get("exhausts", False),
        "card_is_ethereal": kw.get("ethereal", False),
        "card_is_retained": kw.get("retain", False),
        "card_values": vals,
        "card_description_preview_overrides": kw.get("preview_overrides", []),
        "card_play_actions": actions,
        "card_discard_actions": [], "card_end_of_turn_actions": [],
        "card_exhaust_actions": [], "card_draw_actions": [],
        "card_retain_actions": [], "card_right_click_actions": [],
        "card_initial_combat_actions": [],
        "card_add_to_deck_actions": [], "card_remove_from_deck_actions": [],
        "card_transform_in_deck_actions": [],
        "card_play_validators": [], "card_glow_validators": [],
        "card_listeners": [], "card_tags": [],
        "card_upgrade_amount": 0, "card_upgrade_amount_max": 1,
        "card_first_upgrade_property_changes": kw.get("upgrade_props", {}),
        "card_upgrade_value_improvements": kw.get("upgrade_values", {}),
        "card_energy_cost_until_played": -1, "card_energy_cost_until_turn": -1,
        "card_energy_cost_until_combat": -1,
        "card_unremovable_from_deck": False, "card_untransformable_from_deck": False,
        "card_energy_cost_is_variable": kw.get("x_cost", False),
        "card_energy_cost_variable_upper_bound": kw.get("x_bound", -1),
        "card_keyword_object_ids": kw.get("keywords", []),
        "card_first_shuffle_priority": kw.get("topdeck", 0),
        "card_texture_path": "external/sprites/cards/generated/" + oid + ".png", "object_uid": "",
    }
    return {"patch_data": {}, "properties": p}

# ---- STARTER CARDS ----
cards_data.append(mkcard("card_astrology_stellar_strike", "Stellar Strike", 1, ATTACK, BASIC,
    "Deal [damage] damage. If a Star is in the House of Noon, deal [bonus_damage] instead.",
    {"damage": 6, "bonus_damage": 9},
    [{A_ATK: {"actions_on_lethal": [], "time_delay": 0.0}}],
    upgrade_values={"damage": 3, "bonus_damage": 3}))
cards_data.append(mkcard("card_astrology_stellar_guard", "Stellar Guard", 1, SKILL, BASIC,
    "Gain [block] Block. If a Star is in the House of Dusk, gain [bonus_block] instead.",
    {"block": 5, "bonus_block": 8},
    [{A_BLK: {"target_override": SELF, "time_delay": 0.0}}],
    upgrade_values={"block": 3, "bonus_block": 3}))
cards_data.append(mkcard("card_astrology_place_saturn", "Place Saturn", 1, SKILL, BASIC,
    "Place a Star in the House of Dusk. Gain [block] Block.",
    {"star_house": 2, "star_count": 1, "block": 4},
    [{A_PLA: {"star_house": 2, "star_count": 1}}, {A_BLK: {"target_override": SELF}}],
    upgrade_values={"block": 3}))
cards_data.append(mkcard("card_astrology_place_mercury", "Place Mercury", 0, SKILL, BASIC,
    "Place a Star in the House of Dawn.",
    {"star_house": 0, "star_count": 1},
    [{A_PLA: {"star_house": 0, "star_count": 1}}]))
cards_data.append(mkcard("card_astrology_read_heavens", "Read the Heavens", 1, SKILL, BASIC,
    "Scry 3. Draw [draw_count] card.",
    {"draw_count": 1, "max_card_amount": 3},
    [{A_PCK: {"min_card_amount": 0, "max_card_amount": 3, "min_cards_are_required_for_action": False,
     "random_selection": False, "card_pick_type": 0,
     "card_pick_text": "Choose up to {0} card(s) to discard. {1} cards selected",
     "action_data": [{A_DIS: {}}]}}, {A_DRW: {}}],
    upgrade_values={"draw_count": 1}))
cards_data.append(mkcard("card_astrology_destined_strike", "Destined Strike", 2, ATTACK, BASIC,
    "Deal [damage] damage. If this kills an enemy, place a Star in the House of Fate.",
    {"damage": 10, "star_house": 5, "star_count": 1, "number_of_attacks": 1},
    [{A_ATK: {"actions_on_lethal": [{A_PLA: {"star_house": 5, "star_count": 1}}], "time_delay": 0.0}}],
    upgrade_values={"damage": 4}))

# ---- CONSTELLATION POWERS ----
cards_data.append(mkcard("card_astrology_mars_warrior", "Mars, the Warrior", 2, POWER, UNCOMMON,
    "Place a Star in the House of Noon. While this Star orbits, your Attacks deal +[bonus_damage] damage.",
    {"star_house": 1, "star_count": 1, "bonus_damage": 3},
    [{A_PLA: {"star_house": 1, "star_count": 1}}], upgrade_values={"bonus_damage": 2}))
cards_data.append(mkcard("card_astrology_venus_lover", "Venus, the Lover", 2, POWER, UNCOMMON,
    "Place a Star in the House of Dusk. While this Star orbits, gain [block] Block at start of turn.",
    {"star_house": 2, "star_count": 1, "block": 3},
    [{A_PLA: {"star_house": 2, "star_count": 1}}], upgrade_values={"block": 2}))
cards_data.append(mkcard("card_astrology_jupiter_king", "Jupiter, the King", 2, POWER, RARE,
    "Place a Star in a House of your choice. While this Star orbits, you have +1 Energy each turn.",
    {"star_house": 0, "star_count": 1},
    [{A_PLA: {"star_house": 0, "star_count": 1}}], upgrade_values={"star_count": 1}))
cards_data.append(mkcard("card_astrology_saturn_teacher", "Saturn, the Teacher", 2, POWER, RARE,
    "Place a Star in the House of Wisdom. While this Star orbits, when you play a card, add a temporary copy to your hand next turn.",
    {"star_house": 4, "star_count": 1}, [{A_PLA: {"star_house": 4, "star_count": 1}}]))
cards_data.append(mkcard("card_astrology_uranus_awakener", "Uranus, the Awakener", 3, POWER, RARE,
    "Place a Star in the House of Fate. While this Star orbits, a random Star moves an extra House each turn.",
    {"star_house": 5, "star_count": 1}, [{A_PLA: {"star_house": 5, "star_count": 1}}],
    upgrade_props={"card_description": "Place a Star in the House of Fate. 2 random Stars move an extra House each turn."}))
cards_data.append(mkcard("card_astrology_neptune_dreamer", "Neptune, the Dreamer", 2, POWER, UNCOMMON,
    "Place a Star in the House of Night. While this Star orbits, draw [draw_count] extra card at start of turn.",
    {"star_house": 3, "star_count": 1, "draw_count": 1},
    [{A_PLA: {"star_house": 3, "star_count": 1}}], upgrade_values={"draw_count": 1}))
cards_data.append(mkcard("card_astrology_pluto_judge", "Pluto, the Judge", 3, POWER, RARE,
    "Place a Star in the House of Fate. While this Star orbits, the first enemy killed each combat drops double gold.",
    {"star_house": 5, "star_count": 1}, [{A_PLA: {"star_house": 5, "star_count": 1}}]))
cards_data.append(mkcard("card_astrology_binary_star", "Binary Star", 1, POWER, UNCOMMON,
    "Place 2 Stars in the same House (triggers Alignment). Ethereal.",
    {"star_house": 0, "star_count": 2}, [{A_PLA: {"star_house": 0, "star_count": 2}}],
    ethereal=True, keywords=["keyword_ethereal"],
    upgrade_props={"card_is_ethereal": False, "card_description": "Place 2 Stars in the same House (triggers Alignment)."}))

# ---- ALIGNMENT CARDS ----
cards_data.append(mkcard("card_astrology_celestial_alignment", "Celestial Alignment", 1, SKILL, COMMON,
    "Choose a House. If it has 2+ Stars, trigger its Alignment effect. Exhaust.",
    {"star_house": 0}, [{A_ALN: {"star_house": 0}}],
    exhausts=True, keywords=["keyword_exhaust"],
    upgrade_props={"card_exhausts": False, "card_description": "Choose a House. If it has 2+ Stars, trigger its Alignment effect."}))
cards_data.append(mkcard("card_astrology_conjunction", "Conjunction", 1, SKILL, UNCOMMON,
    "Choose 2 Stars in different Houses. Move them both to the House between them.",
    {"rotate_times": 0}, [{A_ROT: {}}]))
cards_data.append(mkcard("card_astrology_opposition", "Opposition", 1, ATTACK, UNCOMMON,
    "If two Stars are 3 Houses apart, deal [damage] damage.",
    {"damage": 14, "number_of_attacks": 1},
    [{A_ATK: {"actions_on_lethal": [], "time_delay": 0.0}}], upgrade_values={"damage": 6}))
cards_data.append(mkcard("card_astrology_grand_trine", "Grand Trine", 2, SKILL, RARE,
    "If Stars occupy 3 equally spaced Houses, gain [energy_amount] Energy and draw [draw_count] cards.",
    {"energy_amount": 2, "draw_count": 3},
    [{A_NRG: {"energy_amount": 2}}, {A_DRW: {"draw_count": 3}}],
    upgrade_values={"energy_amount": 1, "draw_count": 1}))
cards_data.append(mkcard("card_astrology_stellium", "Stellium", 2, SKILL, UNCOMMON,
    "Move all Stars to the most populous House. For each Star moved, gain [block] Block.",
    {"block": 2}, [{A_BLK: {"target_override": SELF}}], upgrade_values={"block": 1}))
cards_data.append(mkcard("card_astrology_retrograde", "Retrograde", 0, SKILL, COMMON,
    "Choose a Star. It moves counter-clockwise one House. Draw [draw_count] card.",
    {"rotate_direction": -1, "rotate_times": 1, "draw_count": 1},
    [{A_ROT: {"rotate_direction": -1, "rotate_times": 1}}, {A_DRW: {"draw_count": 1}}],
    upgrade_values={"draw_count": 1}))
cards_data.append(mkcard("card_astrology_aspect", "Aspect", 1, SKILL, COMMON,
    "Scry 3. Place a Star in the House of Wisdom.",
    {"star_house": 4, "star_count": 1, "max_card_amount": 3},
    [{A_PCK: {"min_card_amount": 0, "max_card_amount": 3, "min_cards_are_required_for_action": False,
     "random_selection": False, "card_pick_type": 0, "card_pick_text": "Choose up to {0} card(s) to discard.",
     "action_data": [{A_DIS: {}}]}}, {A_PLA: {"star_house": 4, "star_count": 1}}],
    upgrade_props={"card_description": "Scry 5. Place a Star in the House of Wisdom."}))
cards_data.append(mkcard("card_astrology_cosmic_mirror", "Cosmic Mirror", 1, SKILL, UNCOMMON,
    "Choose a House. Trigger its Alignment effect without consuming Stars. Exhaust.",
    {"star_house": 0}, [{A_ALN: {"star_house": 0}}],
    exhausts=True, keywords=["keyword_exhaust"],
    upgrade_props={"card_exhausts": False, "card_description": "Choose a House. Trigger its Alignment without consuming Stars."}))
cards_data.append(mkcard("card_astrology_star_swarm", "Star Swarm", 1, ATTACK, COMMON,
    "Deal [damage] damage for each Star you have.",
    {"damage": 2, "number_of_attacks": 1},
    [{A_ATK: {"actions_on_lethal": [], "time_delay": 0.0}}], upgrade_values={"damage": 1}))
cards_data.append(mkcard("card_astrology_astral_projection", "Astral Projection", 2, SKILL, UNCOMMON,
    "Next turn, your Stars do not rotate. Ethereal.",
    {}, [], ethereal=True, keywords=["keyword_ethereal"],
    upgrade_props={"card_is_ethereal": False, "card_description": "Next turn, your Stars do not rotate."}))

# ---- ECLIPSE / REBIRTH CARDS ----
cards_data.append(mkcard("card_astrology_forced_eclipse", "Forced Eclipse", 3, SKILL, RARE,
    "Trigger Eclipse immediately. Deal [eclipse_damage] damage to ALL enemies per 6 Stars consumed.",
    {"eclipse_energy": 2, "eclipse_draw": 5, "eclipse_damage": 12},
    [{A_ECL: {"eclipse_energy": 2, "eclipse_draw": 5, "eclipse_damage": 12}}],
    upgrade_values={"eclipse_damage": 3}))
cards_data.append(mkcard("card_astrology_supernova", "Supernova", 2, ATTACK, RARE,
    "Choose a House. Consume all Stars in it. Deal [damage] damage per Star to ALL enemies.",
    {"damage": 8, "number_of_attacks": 1},
    [{A_CON: {"star_house": 0, "star_count": 99}},
     {A_ATK: {"actions_on_lethal": [], "time_delay": 0.0, "target_override": ALL_EN}}],
    upgrade_values={"damage": 4}))
cards_data.append(mkcard("card_astrology_nova", "Nova", 1, ATTACK, UNCOMMON,
    "Consume 1 Star. Deal [damage] damage to ALL enemies.",
    {"damage": 10, "number_of_attacks": 1},
    [{A_CON: {"star_house": -1, "star_count": 1}},
     {A_ATK: {"actions_on_lethal": [], "time_delay": 0.0, "target_override": ALL_EN}}],
    upgrade_values={"damage": 5}))
cards_data.append(mkcard("card_astrology_starburst", "Starburst", 1, SKILL, COMMON,
    "Consume 1 Star. Gain [block] Block and draw [draw_count] cards.",
    {"block": 6, "draw_count": 2, "star_count": 1},
    [{A_CON: {"star_house": -1, "star_count": 1}}, {A_BLK: {"target_override": SELF}}, {A_DRW: {}}],
    upgrade_values={"block": 3}))
cards_data.append(mkcard("card_astrology_cosmic_rebirth", "Cosmic Rebirth", -1, SKILL, RARE,
    "Consume all Stars. For each Star consumed, gain 1 Energy and place 1 new Star in a random House. Exhaust.",
    {"star_count": 1},
    [{A_CON: {"star_house": -1, "star_count": 99}}, {A_NRG: {"energy_amount": 1}},
     {A_PLA: {"star_house": -1, "star_count": 1}}],
    x_cost=True, exhausts=True, keywords=["keyword_exhaust"],
    upgrade_props={"card_exhausts": False, "card_description": "Consume all Stars. For each Star, gain 1 Energy and place 1 new Star in a random House."}))
cards_data.append(mkcard("card_astrology_heat_death", "Heat Death", 3, ATTACK, RARE,
    "Consume all Stars. Deal [damage] damage per Star. Exhaust.",
    {"damage": 5, "number_of_attacks": 1},
    [{A_CON: {"star_house": -1, "star_count": 99}}, {A_ATK: {"actions_on_lethal": [], "time_delay": 0.0}}],
    exhausts=True, keywords=["keyword_exhaust"], upgrade_values={"damage": 2}))
cards_data.append(mkcard("card_astrology_singularity", "Singularity", 2, SKILL, UNCOMMON,
    "If you have exactly 1 Star, triple all its House bonuses this turn. Exhaust.",
    {}, [], exhausts=True, keywords=["keyword_exhaust"],
    upgrade_props={"card_exhausts": False}))
cards_data.append(mkcard("card_astrology_constellation_shift", "Constellation Shift", 0, SKILL, COMMON,
    "Consume 1 Star. Place [star_count] Stars in different Houses.",
    {"star_count": 2, "star_house": 0},
    [{A_CON: {"star_house": -1, "star_count": 1}}, {A_PLA: {"star_house": 0, "star_count": 2}}],
    upgrade_values={"star_count": 1}))

# ---- DESTINY / PROPHECY CARDS ----
cards_data.append(mkcard("card_astrology_prophecy", "Prophecy", 1, SKILL, UNCOMMON,
    "Scry 5. Choose 1 to add to your hand.",
    {"max_card_amount": 5, "draw_count": 1},
    [{A_PCK: {"min_card_amount": 1, "max_card_amount": 5, "min_cards_are_required_for_action": False,
     "random_selection": False, "card_pick_type": 0, "card_pick_text": "Prophecy: Choose 1 card to take.",
     "action_data": [{A_AHD: {}}]}}],
    upgrade_props={"card_description": "Scry 8. Choose 2 to add to your hand."}))
cards_data.append(mkcard("card_astrology_fates_thread", "Fate's Thread", 1, SKILL, COMMON,
    "Scry [max_card_amount].",
    {"max_card_amount": 5},
    [{A_PCK: {"min_card_amount": 0, "max_card_amount": 5, "min_cards_are_required_for_action": False,
     "random_selection": False, "card_pick_type": 0, "card_pick_text": "Scry: Choose up to {0} card(s) to discard.",
     "action_data": [{A_DIS: {}}]}}],
    upgrade_values={"max_card_amount": 3}))
cards_data.append(mkcard("card_astrology_weave_destiny", "Weave Destiny", 2, SKILL, UNCOMMON,
    "Choose a card in your hand. It gains Retain. Next turn, it costs 0.",
    {}, [], retain=True))
cards_data.append(mkcard("card_astrology_predetermined_outcome", "Predetermined Outcome", 3, SKILL, RARE,
    "ALL enemy attacks deal 0 damage next turn. Exhaust.",
    {}, [], exhausts=True, keywords=["keyword_exhaust"],
    upgrade_props={"card_exhausts": False, "card_description": "ALL enemy attacks deal 0 damage next turn. Draw 2 cards."}))
cards_data.append(mkcard("card_astrology_omen", "Omen", 1, SKILL, COMMON,
    "Place a Star in a random House. Draw [draw_count] card.",
    {"draw_count": 1, "star_count": 1, "star_house": -1},
    [{A_PLA: {"star_house": -1, "star_count": 1}}, {A_DRW: {"draw_count": 1}}],
    upgrade_values={"star_count": 1}))
cards_data.append(mkcard("card_astrology_astral_forecast", "Astral Forecast", 1, SKILL, COMMON,
    "Gain [block] Block. Place a Star in a random House.",
    {"block": 4, "star_count": 1, "star_house": -1},
    [{A_BLK: {"target_override": SELF}}, {A_PLA: {"star_house": -1, "star_count": 1}}],
    upgrade_values={"block": 3}))
cards_data.append(mkcard("card_astrology_rewrite_fate", "Rewrite Fate", 2, SKILL, RARE,
    "If you would die this combat, heal to 1 HP and consume all Stars. Exhaust.",
    {}, [], exhausts=True, keywords=["keyword_exhaust"],
    upgrade_props={"card_exhausts": False, "card_description": "If you would die this combat, heal to 25% HP and consume all Stars. Exhaust."}))
cards_data.append(mkcard("card_astrology_inertia", "Inertia", 1, SKILL, UNCOMMON,
    "This turn, Stars do not rotate. Gain [block] Block.",
    {"block": 5}, [{A_BLK: {"target_override": SELF}}], upgrade_values={"block": 3}))
cards_data.append(mkcard("card_astrology_accelerate", "Accelerate", 1, SKILL, UNCOMMON,
    "All Stars rotate one extra House immediately. Draw [draw_count] card.",
    {"rotate_times": 1, "draw_count": 1},
    [{A_ROT: {"rotate_direction": 1, "rotate_times": 1}}, {A_DRW: {"draw_count": 1}}],
    upgrade_values={"rotate_times": 1}))

# ---- CELESTIAL / GENERAL CARDS ----
cards_data.append(mkcard("card_astrology_starfall", "Starfall", 1, ATTACK, COMMON,
    "Deal [damage] damage. Place a Star in the House of Noon.",
    {"damage": 7, "star_house": 1, "star_count": 1, "number_of_attacks": 1},
    [{A_ATK: {"actions_on_lethal": [], "time_delay": 0.0}}, {A_PLA: {"star_house": 1, "star_count": 1}}],
    upgrade_values={"damage": 3}))
cards_data.append(mkcard("card_astrology_moonshield", "Moonshield", 1, SKILL, COMMON,
    "Gain [block] Block. Place a Star in the House of Dusk.",
    {"block": 7, "star_house": 2, "star_count": 1},
    [{A_BLK: {"target_override": SELF}}, {A_PLA: {"star_house": 2, "star_count": 1}}],
    upgrade_values={"block": 3}))
cards_data.append(mkcard("card_astrology_solar_flare", "Solar Flare", 2, ATTACK, UNCOMMON,
    "Deal [damage] damage. ALL Stars advance one House.",
    {"damage": 12, "rotate_times": 1, "number_of_attacks": 1},
    [{A_ATK: {"actions_on_lethal": [], "time_delay": 0.0}}, {A_ROT: {"rotate_direction": 1, "rotate_times": 1}}],
    upgrade_values={"damage": 4}))
cards_data.append(mkcard("card_astrology_lunar_tide", "Lunar Tide", 2, SKILL, UNCOMMON,
    "Gain [block] Block. ALL Stars move backward one House.",
    {"block": 10, "rotate_direction": -1, "rotate_times": 1},
    [{A_BLK: {"target_override": SELF}}, {A_ROT: {"rotate_direction": -1, "rotate_times": 1}}],
    upgrade_values={"block": 4}))
cards_data.append(mkcard("card_astrology_meteor_shower", "Meteor Shower", -1, ATTACK, UNCOMMON,
    "Deal [damage] damage X times to a random enemy. Place X Stars in random Houses.",
    {"damage": 4, "star_count": 1, "number_of_attacks": 1},
    [{A_ATK: {"actions_on_lethal": [], "time_delay": 0.0}}, {A_PLA: {"star_house": -1, "star_count": 1}}],
    x_cost=True, upgrade_values={"damage": 2}))
cards_data.append(mkcard("card_astrology_cosmic_ray", "Cosmic Ray", 1, ATTACK, COMMON,
    "Deal [damage] damage. Gain bonuses equal to the Houses where Stars currently sit.",
    {"damage": 6, "number_of_attacks": 1},
    [{A_ATK: {"actions_on_lethal": [], "time_delay": 0.0}}], upgrade_values={"damage": 3}))
cards_data.append(mkcard("card_astrology_gravity_well", "Gravity Well", 2, SKILL, UNCOMMON,
    "ALL enemies lose [strength_loss] Strength this turn. Place a Star in the House of Night.",
    {"star_house": 3, "star_count": 1, "strength_loss": 2},
    [{A_STA: {"status_effect_object_id": "status_effect_weaken", "status_charge_amount": 2, "target_override": ALL_EN}},
     {A_PLA: {"star_house": 3, "star_count": 1}}],
    upgrade_values={"strength_loss": 2}))
cards_data.append(mkcard("card_astrology_event_horizon", "Event Horizon", 3, POWER, RARE,
    "At start of turn, draw [draw_count] card and place a Star in the House of Night.",
    {"draw_count": 1, "star_house": 3, "star_count": 1},
    [{A_DRW: {}}, {A_PLA: {"star_house": 3, "star_count": 1}}], upgrade_values={"draw_count": 1}))
cards_data.append(mkcard("card_astrology_zodiac_cycle", "Zodiac Cycle", 2, POWER, RARE,
    "At start of turn, rotate Stars one extra House.",
    {"rotate_times": 1}, [{A_ROT: {"rotate_direction": 1, "rotate_times": 1}}]))
cards_data.append(mkcard("card_astrology_dark_matter", "Dark Matter", 1, SKILL, UNCOMMON,
    "Gain 1 Intangible. Place a Star in the House of Fate. Exhaust.",
    {"star_house": 5, "star_count": 1}, [{A_PLA: {"star_house": 5, "star_count": 1}}],
    exhausts=True, keywords=["keyword_exhaust"],
    upgrade_props={"card_exhausts": False, "card_description": "Gain 1 Intangible. Place a Star in the House of Fate."}))
cards_data.append(mkcard("card_astrology_celestial_shield", "Celestial Shield", 2, SKILL, UNCOMMON,
    "Gain Block equal to (Stars x [block_multiplier]).",
    {"block": 4, "block_multiplier": 4}, [{A_BLK: {"target_override": SELF}}],
    upgrade_values={"block_multiplier": 2}))
cards_data.append(mkcard("card_astrology_astral_strike", "Astral Strike", 2, ATTACK, RARE,
    "Deal damage equal to (Stars x [damage_multiplier]). If you have 5+ Stars, deal double.",
    {"damage": 5, "damage_multiplier": 5, "number_of_attacks": 1},
    [{A_ATK: {"actions_on_lethal": [], "time_delay": 0.0}}], upgrade_values={"damage_multiplier": 2}))
cards_data.append(mkcard("card_astrology_stardust", "Stardust", 1, SKILL, COMMON,
    "Gain [block] Block. Place a Star in a random House.",
    {"block": 3, "star_house": -1, "star_count": 1},
    [{A_BLK: {"target_override": SELF}}, {A_PLA: {"star_house": -1, "star_count": 1}}],
    upgrade_values={"block": 2}))

# ---- BUILD-DEFINING RARE POWERS ----
cards_data.append(mkcard("card_astrology_fixed_star", "Fixed Star", 2, POWER, RARE,
    "Choose a House. The first Star placed there never rotates.",
    {}, [], upgrade_props={"card_description": "Choose a House. The first 2 Stars placed there never rotate."}))
cards_data.append(mkcard("card_astrology_retrograde_motion", "Retrograde Motion", 2, POWER, RARE,
    "At start of turn, ALL Stars rotate counter-clockwise instead of clockwise.",
    {}, [], upgrade_props={"card_description": "At start of turn, choose the rotation direction."}))
cards_data.append(mkcard("card_astrology_grand_cross", "Grand Cross", 3, POWER, RARE,
    "If 4 Stars are in opposite Houses at turn start, deal [damage] to ALL enemies and gain [energy_amount] Energy.",
    {"damage": 20, "energy_amount": 2}, [], upgrade_values={"damage": 10}))
cards_data.append(mkcard("card_astrology_stellar_nursery", "Stellar Nursery", 2, POWER, RARE,
    "At end of turn, if you have < 3 Stars, place a Star in a random House.",
    {"star_count": 1, "star_house": -1}, [{A_PLA: {"star_house": -1, "star_count": 1}}],
    upgrade_props={"card_description": "At end of turn, if you have < 3 Stars, place 2 Stars in random Houses."}))
cards_data.append(mkcard("card_astrology_twin_destiny", "Twin Destiny", 3, POWER, RARE,
    "Choose a House. ALL Alignment effects in that House trigger twice.", {}, []))
cards_data.append(mkcard("card_astrology_cosmic_inflation", "Cosmic Inflation", 2, POWER, RARE,
    "When you play a card costing 2+, place a Star in the House of Dawn.",
    {"star_house": 0, "star_count": 1}, [{A_PLA: {"star_house": 0, "star_count": 1}}]))
cards_data.append(mkcard("card_astrology_dark_nebula", "Dark Nebula", 2, POWER, RARE,
    "Stars you consume deal [damage] damage to a random enemy when consumed.",
    {"damage": 3}, [], upgrade_values={"damage": 2}))
cards_data.append(mkcard("card_astrology_astral_resonance", "Astral Resonance", 2, POWER, RARE,
    "When a Star enters the House of Wisdom, add a random card from draw pile to hand.",
    {"draw_count": 1}, [{A_DRW: {"draw_count": 1}}],
    upgrade_props={"card_description": "When a Star enters the House of Wisdom, draw 2 cards."}))

# ---- EXTRA COMMONS ----
cards_data.append(mkcard("card_astrology_quick_read", "Quick Read", 0, SKILL, COMMON,
    "Scry 2. If a Star is in the House of Wisdom, draw [draw_count] card.",
    {"max_card_amount": 2, "draw_count": 1},
    [{A_PCK: {"min_card_amount": 0, "max_card_amount": 2, "min_cards_are_required_for_action": False,
     "random_selection": False, "card_pick_type": 0, "card_pick_text": "Choose up to {0} card(s) to discard.",
     "action_data": [{A_DIS: {}}]}}, {A_DRW: {"draw_count": 1}}],
    upgrade_values={"max_card_amount": 1, "draw_count": 1}))
cards_data.append(mkcard("card_astrology_orbital_strike", "Orbital Strike", 1, ATTACK, COMMON,
    "Deal [damage] damage. If a Star is in the House of Noon, deal +[bonus_damage] damage.",
    {"damage": 8, "bonus_damage": 4, "number_of_attacks": 1},
    [{A_ATK: {"actions_on_lethal": [], "time_delay": 0.0}}],
    upgrade_values={"damage": 3, "bonus_damage": 2}))
cards_data.append(mkcard("card_astrology_dusk_barrier", "Dusk Barrier", 1, SKILL, COMMON,
    "Gain [block] Block. If a Star is in the House of Dusk, gain +[bonus_block] Block.",
    {"block": 7, "bonus_block": 4}, [{A_BLK: {"target_override": SELF}}],
    upgrade_values={"block": 2, "bonus_block": 2}))
cards_data.append(mkcard("card_astrology_stargazer", "Stargazer", 1, SKILL, COMMON,
    "Place a Star opposite your most populous House. Scry 2.",
    {"star_house": 0, "star_count": 1, "max_card_amount": 2},
    [{A_PLA: {"star_house": 0, "star_count": 1}},
     {A_PCK: {"min_card_amount": 0, "max_card_amount": 2, "min_cards_are_required_for_action": False,
     "random_selection": False, "card_pick_type": 0, "card_pick_text": "Choose up to {0} card(s) to discard.",
     "action_data": [{A_DIS: {}}]}}],
    upgrade_values={"max_card_amount": 2}))

# ---- CURSE ----
cards_data.append(mkcard("card_astrology_bad_omen", "Bad Omen", 99, CURSE, GENERATED,
    "Unplayable. At end of turn, remove 1 Star if in hand. Ethereal.",
    {}, [], ethereal=True, keywords=["keyword_ethereal"], playable=False))

for c in cards_data:
    wj(os.path.join(CARDS, c["properties"]["object_id"] + ".json"), c)

rc = {0:0, 1:0, 2:0, 3:0, 4:0}
for c in cards_data:
    rc[c["properties"]["card_rarity"]] += 1
print(f"[3/6] Generated {len(cards_data)} cards (B:{rc[0]} C:{rc[1]} U:{rc[2]} R:{rc[3]} G:{rc[4]})")

# ── Step 4: Artifacts ─────────────────────────────────────────────────
def mkart(oid, name, desc, rarity, **kw):
    return {"patch_data": {}, "properties": dict(
        object_id=oid, artifact_name=name, artifact_description=desc,
        artifact_texture_path="",
        artifact_script_path=kw.pop("script", "res://scripts/artifacts/BaseArtifact.gd"),
        artifact_counter=0, artifact_counter_max=kw.pop("max_counter", 1),
        artifact_counter_reset_on_turn_start=kw.pop("turn_reset", -1),
        artifact_counter_reset_on_combat_end=kw.pop("combat_reset", -1),
        artifact_counter_wraparound=kw.pop("wrap", True),
        artifact_color_id=kw.pop("color", "color_blue"),
        artifact_appears_in_artifact_packs=kw.pop("in_packs", True),
        artifact_rarity=rarity,
        artifact_max_counter_actions=kw.pop("max_actions", []),
        artifact_add_actions=kw.pop("add_actions", []),
        artifact_remove_actions=kw.pop("remove_actions", []),
        artifact_right_click_actions=kw.pop("right_click", []),
        artifact_right_click_validators=[],
        artifact_first_turn_actions=kw.pop("first_turn", []),
        artifact_end_of_combat_actions=kw.pop("end_combat", []),
        artifact_turn_start_actions=kw.pop("turn_start", []),
        artifact_turn_end_actions=kw.pop("turn_end", []),
        object_uid="", **kw)}

arts = [
    mkart("artifact_brass_astrolabe", "Brass Astrolabe",
        "At combat start, place 2 Stars in random Houses. At end of turn, rotate Stars and check Eclipse.",
        BASIC, script="res://scripts/artifacts/ArtifactBrassAstrolabe.gd", in_packs=False),
    mkart("artifact_star_map", "Star Map", "At the start of each combat, Scry 3.", COMMON,
        first_turn=[{A_PCK: {"min_card_amount": 0, "max_card_amount": 3, "min_cards_are_required_for_action": False,
         "random_selection": False, "card_pick_type": 0, "card_pick_text": "Star Map: Choose cards to discard.",
         "action_data": [{A_DIS: {}}]}}]),
    mkart("artifact_lens_of_clarity", "Lens of Clarity", "Whenever you Scry, Scry 1 additional card.", COMMON),
    mkart("artifact_mercury_quill", "Mercury's Quill", "The first Constellation card you play each combat costs 0.", COMMON),
    mkart("artifact_comet_shard", "Comet Shard", "Whenever you consume a Star, gain 2 Block.", COMMON),
    mkart("artifact_lunar_calendar", "Lunar Calendar", "Every 3rd turn, Stars rotate one extra House.", UNCOMMON,
        max_counter=3, turn_reset=0, max_actions=[{A_ROT: {"rotate_direction": 1, "rotate_times": 1}}]),
    mkart("artifact_jupiter_favor", "Jupiter's Favor", "When you place a Star in an empty House, gain 1 Energy.", UNCOMMON),
    mkart("artifact_constellation_globe", "Constellation Globe",
        "At combat start, choose which Houses receive the 2 starting Stars.", UNCOMMON),
    mkart("artifact_eclipse_prism", "Eclipse Prism", "When Eclipse triggers, heal 10 HP.", UNCOMMON),
    mkart("artifact_saturn_ring", "Saturn's Ring", "Stars in the House of Dusk give +1 extra Block per Star.", UNCOMMON),
    mkart("artifact_cosmic_clock", "Cosmic Clock", "See which House each Star will be in next turn on the Star Chart.", RARE),
    mkart("artifact_nebula_gem", "Nebula Gem", "When you place a Star, 50% chance for a second Star in the same House.", RARE),
    mkart("artifact_dark_star", "Dark Star",
        "The first time you would die each combat, consume all Stars, heal to 1 HP, and gain 1 Intangible.", RARE),
    mkart("artifact_zodiac_codex", "Zodiac Codex", "At start of turn, if any House has 3+ Stars, gain 1 Energy.", RARE,
        turn_start=[{A_NRG: {"energy_amount": 1}}]),
    mkart("artifact_heliocentric_model", "Heliocentric Model",
        "Gain 1 Energy at start of turn. Stars rotate counter-clockwise.", BOSS,
        turn_start=[{A_NRG: {"energy_amount": 1}}]),
    mkart("artifact_telescope_of_fate", "Telescope of Fate",
        "At start of turn, Scry 3. You may place a Star in any House.", BOSS,
        turn_start=[{A_PCK: {"min_card_amount": 0, "max_card_amount": 3, "min_cards_are_required_for_action": False,
         "random_selection": False, "card_pick_type": 0, "card_pick_text": "Telescope: Choose cards to discard.",
         "action_data": [{A_DIS: {}}]}}, {A_PLA: {"star_house": 0, "star_count": 1}}]),
    mkart("artifact_orrery_of_worlds", "Orrery of Worlds",
        "Constellation cards place 1 extra Star. Gain 1 less Energy per turn.", BOSS),
]
for a in arts:
    wj(os.path.join(ARTIFACTS, a["properties"]["object_id"] + ".json"), a)
print(f"[4/6] Generated {len(arts)} artifacts")

# ── Step 5: Potions ───────────────────────────────────────────────────
pots = [
    ("consumable_starlight_elixir", "Starlight Elixir", "Place 2 Stars in random Houses.", 0,
      [{A_PLA: {"star_house": -1, "star_count": 2}}]),
    ("consumable_alignment_tincture", "Alignment Tincture", "Trigger the Alignment of any House.", 0,
      [{A_ALN: {"star_house": 0}}]),
    ("consumable_eclipse_in_bottle", "Eclipse in a Bottle", "Trigger Eclipse immediately.", 1,
      [{A_ECL: {"eclipse_energy": 2, "eclipse_draw": 5, "eclipse_damage": 12}}]),
    ("consumable_cosmic_tonic", "Cosmic Tonic", "Gain 2 Energy. Stars rotate 2 Houses.", 1,
      [{A_NRG: {"energy_amount": 2}}, {A_ROT: {"rotate_direction": 1, "rotate_times": 2}}]),
    ("consumable_nebula_phial", "Nebula Phial", "Place a Star in EVERY House.", 2,
      [{A_PLA: {"star_house": i, "star_count": 1}} for i in range(6)]),
]
for p in pots:
    wj(os.path.join(CONSUMABLES, p[0] + ".json"), {"patch_data": {}, "properties": {
        "object_id": p[0], "consumable_name": p[1], "consumable_description": p[2],
        "consumable_texture_path": "", "consumable_requires_target": False,
        "consumable_rarity": p[3], "consumable_actions": p[4], "object_uid": ""}})
print(f"[5/6] Generated {len(pots)} potions")

# ── Step 6: character_blue.json ───────────────────────────────────────
wj(os.path.join(CHARS, "character_blue.json"), {"patch_data": {}, "properties": {
    "character_name": "The Astrologer", "character_color_id": "color_blue",
    "character_description": "The Astrologer reads the stars and bends fate. Place Stars into the Star Chart, watch them orbit through 6 Houses, and unleash devastating Alignments and Eclipses.",
    "character_icon_texture_path": "external/sprites/characters/character_blue/paperkeepericon.png",
    "character_player_id": "player_blue",
    "character_starting_artifact_ids": ["artifact_brass_astrolabe"],
    "character_starting_artifact_pack_ids": ["artifact_pack_white", "artifact_pack_blue"],
    "character_starting_card_draft_card_pack_ids": ["card_pack_blue"],
    "character_starting_card_object_ids": [
        "card_astrology_stellar_strike", "card_astrology_stellar_strike",
        "card_astrology_stellar_strike", "card_astrology_stellar_strike",
        "card_astrology_stellar_guard", "card_astrology_stellar_guard",
        "card_astrology_stellar_guard", "card_astrology_stellar_guard",
        "card_astrology_place_saturn", "card_astrology_place_mercury",
        "card_astrology_read_heavens", "card_astrology_destined_strike",
    ],
    "character_starting_health": 72, "character_starting_money": 99,
    "character_text_energy_texture_path": "external/sprites/characters/character_blue/character_blue_text_energy.png",
    "character_texture_path": "external/sprites/characters/character_blue/paperkeeper.png",
    "character_background_texture_path": "", "object_id": "character_blue",
}})
wj(os.path.join(CUI, "custom_ui_star_chart.json"), {"patch_data": {}, "properties": {
    "object_id": "custom_ui_star_chart", "custom_ui_asset_path": "",
    "custom_ui_description": "The Astrologer's Star Chart",
}})
print("[6/6] Updated character_blue.json + CustomUIData")
print("\n=== ALL FILES GENERATED SUCCESSFULLY ===")
print(f"Cards: {len(cards_data)} | Artifacts: {len(arts)} | Potions: {len(pots)}")
print(f"In {CARDS}")
print(f"In {ARTIFACTS}")
print(f"In {CONSUMABLES}")
