# -*- coding: utf-8 -*-
"""Helper to inject code into Scripts.gd and create action files."""
import os

PROJECT = r"D:\code\slaytheword\slayword"

# ── 1. Add constants to Scripts.gd ──────────────────────────────────────
with open(os.path.join(PROJECT, "autoload", "Scripts.gd"), "r", encoding="utf-8") as f:
    content = f.read()

marker = 'const ACTION_UPGRADE_CARDS: String = "res://scripts/actions/cardset_actions/ActionUpgradeCards.gd"'
new_block = '''const ACTION_UPGRADE_CARDS: String = "res://scripts/actions/cardset_actions/ActionUpgradeCards.gd"

# Star Chart (Astrologer)
const ACTION_PLACE_STAR: String = "res://scripts/actions/star_chart_actions/ActionPlaceStar.gd"
const ACTION_CONSUME_STAR: String = "res://scripts/actions/star_chart_actions/ActionConsumeStar.gd"
const ACTION_ROTATE_STARS: String = "res://scripts/actions/star_chart_actions/ActionRotateStars.gd"
const ACTION_ECLIPSE: String = "res://scripts/actions/star_chart_actions/ActionEclipse.gd"
const ACTION_TRIGGER_ALIGNMENT: String = "res://scripts/actions/star_chart_actions/ActionTriggerAlignment.gd"'''

if marker in content:
    content = content.replace(marker, new_block)
    with open(os.path.join(PROJECT, "autoload", "Scripts.gd"), "w", encoding="utf-8", newline="\n") as f:
        f.write(content)
    print("  Added Star Chart action constants to Scripts.gd")
else:
    print("  ERROR: marker not found in Scripts.gd")

# ── 2. Create action scripts ───────────────────────────────────────────
actions_dir = os.path.join(PROJECT, "scripts", "actions", "star_chart_actions")
os.makedirs(actions_dir, exist_ok=True)

# Helper to get star chart state
STAR_CHART_HELPER = '''
# Star Chart helpers — star chart state lives in Global.player_data.player_values["star_chart"]
# star_chart is an Array[int] of length 6, one per House (0=Dawn, 1=Noon, 2=Dusk, 3=Night, 4=Wisdom, 5=Fate)

static func get_star_chart() -> Array:
\tvar arr = Global.player_data.player_values.get("star_chart", [])
\tif typeof(arr) != TYPE_ARRAY or arr.size() != 6:
\t\tarr = [0, 0, 0, 0, 0, 0]
\t\tGlobal.player_data.player_values["star_chart"] = arr
\treturn arr

static func get_star_count(house: int) -> int:
\tvar chart = get_star_chart()
\treturn int(chart[clamp(house, 0, 5)])

static func get_total_stars() -> int:
\tvar chart = get_star_chart()
\tvar total := 0
\tfor c in chart:
\t\ttotal += int(c)
\treturn total

static func place_star(house: int) -> void:
\tvar chart = get_star_chart()
\tvar h := clamp(house, 0, 5)
\tchart[h] = int(chart[h]) + 1
\tSignals.star_placed.emit(h)

static func consume_stars(house: int, count: int) -> int:
\tvar chart = get_star_chart()
\tvar h := clamp(house, 0, 5)
\tvar available := int(chart[h])
\tvar taken := mini(count, available)
\tchart[h] = available - taken
\tif taken > 0:
\t\tSignals.star_consumed.emit(h, taken)
\treturn taken

static func rotate_stars() -> void:
\tvar chart = get_star_chart()
\tvar last := int(chart[5])
\tfor i in range(5, 0, -1):
\t\tchart[i] = int(chart[i - 1])
\tchart[0] = last
\tSignals.stars_rotated.emit()

static func check_eclipse() -> bool:
\tvar chart = get_star_chart()
\tfor c in chart:
\t\tif int(c) < 1:
\t\t\treturn false
\treturn true

static func trigger_eclipse() -> int:
\tvar chart = get_star_chart()
\tvar total := 0
\tfor i in range(6):
\t\ttotal += int(chart[i])
\t\tchart[i] = 0
\tSignals.eclipse_triggered.emit(total)
\treturn total

# House bonuses (passive, applied when star exists in that house)
static func get_house_passive_bonus() -> Dictionary:
\tvar chart = get_star_chart()
\treturn {
\t\t"bonus_energy": 1 if int(chart[0]) > 0 else 0,      # House of Dawn
\t\t"bonus_damage": 2 if int(chart[1]) > 0 else 0,       # House of Noon
\t\t"bonus_block": 2 if int(chart[2]) > 0 else 0,        # House of Dusk
\t\t"bonus_draw": 1 if int(chart[3]) > 0 else 0,         # House of Night
\t\t"bonus_duplicate": int(chart[4]) > 0,                # House of Wisdom
\t\t"bonus_random": int(chart[5]) > 0,                   # House of Fate
\t}
'''

# Create the helper script
helper_path = os.path.join(actions_dir, "StarChartHelper.gd")
with open(helper_path, "w", encoding="utf-8", newline="\n") as f:
    f.write('extends RefCounted\n\n')
    f.write(STAR_CHART_HELPER.replace('\\t', '\t'))
print("  Created StarChartHelper.gd")

# ActionPlaceStar
place_star_gd = '''extends BaseAction
## Place a Star into a specific House of the Star Chart.

func perform_action():
\tvar action_interceptor_processors: Array[ActionInterceptorProcessor] = _intercept_action([])
\tfor aip in action_interceptor_processors:
\t\tvar house: int = aip.get_shadowed_action_values("star_house", 0)
\t\tvar count: int = aip.get_shadowed_action_values("star_count", 1)
\t\tfor _i in range(count):
\t\t\tStarChartHelper.place_star(house)

func is_action_async() -> bool:
\treturn false
'''
with open(os.path.join(actions_dir, "ActionPlaceStar.gd"), "w", encoding="utf-8", newline="\n") as f:
    f.write(place_star_gd)
print("  Created ActionPlaceStar.gd")

# ActionConsumeStar
consume_star_gd = '''extends BaseAction
## Consume Stars from a specific House or from all Houses.

func perform_action():
\tvar action_interceptor_processors: Array[ActionInterceptorProcessor] = _intercept_action([])
\tfor aip in action_interceptor_processors:
\t\tvar house: int = aip.get_shadowed_action_values("star_house", -1)
\t\tvar count: int = aip.get_shadowed_action_values("star_count", 1)
\t\tvar consumed := 0
\t\tif house < 0:
\t\t\t# Consume from the most populous house
\t\t\tvar chart = StarChartHelper.get_star_chart()
\t\t\tvar best_house := 0
\t\t\tvar best_count := 0
\t\t\tfor i in range(6):
\t\t\t\tif int(chart[i]) > best_count:
\t\t\t\t\tbest_count = int(chart[i])
\t\t\t\t\tbest_house = i
\t\t\tconsumed = StarChartHelper.consume_stars(best_house, count)
\t\telse:
\t\t\tconsumed = StarChartHelper.consume_stars(house, count)
\t\t# Store result in player_values for other actions to read
\t\tGlobal.player_data.player_values["_last_consumed"] = consumed

func is_action_async() -> bool:
\treturn false
'''
with open(os.path.join(actions_dir, "ActionConsumeStar.gd"), "w", encoding="utf-8", newline="\n") as f:
    f.write(consume_star_gd)
print("  Created ActionConsumeStar.gd")

# ActionRotateStars
rotate_stars_gd = '''extends BaseAction
## Rotate all Stars clockwise (or counter-clockwise) through the Houses.

func perform_action():
\tvar action_interceptor_processors: Array[ActionInterceptorProcessor] = _intercept_action([])
\tfor aip in action_interceptor_processors:
\t\tvar direction: int = aip.get_shadowed_action_values("rotate_direction", 1)
\t\tvar times: int = aip.get_shadowed_action_values("rotate_times", 1)
\t\tfor _t in range(times):
\t\t\tif direction >= 0:
\t\t\t\tStarChartHelper.rotate_stars()
\t\t\telse:
\t\t\t\t# Counter-clockwise: reverse rotation
\t\t\t\tvar chart = StarChartHelper.get_star_chart()
\t\t\t\tvar first := int(chart[0])
\t\t\t\tfor i in range(5):
\t\t\t\t\tchart[i] = int(chart[i + 1])
\t\t\t\tchart[5] = first
\t\t\t\tSignals.stars_rotated.emit()

func is_action_async() -> bool:
\treturn false
'''
with open(os.path.join(actions_dir, "ActionRotateStars.gd"), "w", encoding="utf-8", newline="\n") as f:
    f.write(rotate_stars_gd)
print("  Created ActionRotateStars.gd")

# ActionEclipse
eclipse_gd = '''extends BaseAction
## Trigger Eclipse: consume all Stars, gain energy + draw + damage based on total stars consumed.

func perform_action():
\tvar action_interceptor_processors: Array[ActionInterceptorProcessor] = _intercept_action([])
\tfor aip in action_interceptor_processors:
\t\tvar total := StarChartHelper.trigger_eclipse()
\t\tif total > 0:
\t\t\tvar energy_gain: int = aip.get_shadowed_action_values("eclipse_energy", 2)
\t\t\tvar draw_count: int = aip.get_shadowed_action_values("eclipse_draw", 5)
\t\t\tvar damage: int = aip.get_shadowed_action_values("eclipse_damage", 0)
\t\t\t# Gain energy
\t\t\tGlobal.player_data.player_energy += energy_gain
\t\t\tSignals.energy_added.emit(energy_gain)
\t\t\t# Draw cards
\t\t\tSignals.card_draw_requested.emit(draw_count, Global.player_data.PLAYER_DEFAULT_HAND_CARD_COUNT_MAX)
\t\t\t# Deal damage to all enemies
\t\t\tif damage > 0:
\t\t\t\tvar actual_damage := damage * (total / 6) if total >= 6 else 0
\t\t\t\tif actual_damage > 0:
\t\t\t\t\tvar enemies := Global.get_tree().get_nodes_in_group("enemies")
\t\t\t\t\tfor enemy in enemies:
\t\t\t\t\t\tif enemy.is_alive():
\t\t\t\t\t\t\tenemy.damage(actual_damage, true)

func is_action_async() -> bool:
\treturn false
'''
with open(os.path.join(actions_dir, "ActionEclipse.gd"), "w", encoding="utf-8", newline="\n") as f:
    f.write(eclipse_gd)
print("  Created ActionEclipse.gd")

# ActionTriggerAlignment
alignment_gd = '''extends BaseAction
## Trigger the Alignment effect for a specific House.

func perform_action():
\tvar action_interceptor_processors: Array[ActionInterceptorProcessor] = _intercept_action([])
\tfor aip in action_interceptor_processors:
\t\tvar house: int = aip.get_shadowed_action_values("star_house", 0)
\t\tvar stars := StarChartHelper.get_star_count(house)
\t\tif stars < 2:
\t\t\treturn
\t\tSignals.alignment_triggered.emit(house, stars)
\t\tmatch house:
\t\t\t0:  # Dawn - double energy
\t\t\t\tGlobal.player_data.player_energy += 2
\t\t\t\tSignals.energy_added.emit(2)
\t\t\t1:  # Noon - damage all enemies
\t\t\t\tvar dmg := stars * 3
\t\t\t\tvar enemies := Global.get_tree().get_nodes_in_group("enemies")
\t\t\t\tfor enemy in enemies:
\t\t\t\t\tif enemy.is_alive():
\t\t\t\t\t\tenemy.damage(dmg, false)
\t\t\t2:  # Dusk - gain block
\t\t\t\tvar blk := stars * 2
\t\t\t\tGlobal.player_data.player_block += blk
\t\t\t\tSignals.combatant_block_added.emit(Global.get_player())
\t\t\t3:  # Night - draw
\t\t\t\tSignals.card_draw_requested.emit(stars, Global.player_data.PLAYER_DEFAULT_HAND_CARD_COUNT_MAX)
\t\t\t4:  # Wisdom - upgrade random card
\t\t\t\tvar hand := Global.player_data.player_hand.duplicate()
\t\t\t\tif not hand.is_empty():
\t\t\t\t\thand.shuffle()
\t\t\t\t\tfor card in hand:
\t\t\t\t\t\tif card.card_upgrade_amount < card.card_upgrade_amount_max:
\t\t\t\t\t\t\tcard.upgrade_card()
\t\t\t\t\t\t\tbreak
\t\t\t5:  # Fate - random bonus
\t\t\t\tvar r := randi() % 4
\t\t\t\tmatch r:
\t\t\t\t\t0: Global.player_data.player_energy += 1; Signals.energy_added.emit(1)
\t\t\t\t\t1:
\t\t\t\t\t\tvar enemies2 := Global.get_tree().get_nodes_in_group("enemies")
\t\t\t\t\t\tfor enemy in enemies2:
\t\t\t\t\t\t\tif enemy.is_alive():
\t\t\t\t\t\t\t\tenemy.damage(stars * 2, false)
\t\t\t\t\t2:
\t\t\t\t\t\tGlobal.player_data.player_block += stars * 2
\t\t\t\t\t\tSignals.combatant_block_added.emit(Global.get_player())
\t\t\t\t\t3: Signals.card_draw_requested.emit(stars, Global.player_data.PLAYER_DEFAULT_HAND_CARD_COUNT_MAX)

func is_action_async() -> bool:
\treturn false
'''
with open(os.path.join(actions_dir, "ActionTriggerAlignment.gd"), "w", encoding="utf-8", newline="\n") as f:
    f.write(alignment_gd)
print("  Created ActionTriggerAlignment.gd")

print("\nAll actions created. Scripts.gd updated.")
