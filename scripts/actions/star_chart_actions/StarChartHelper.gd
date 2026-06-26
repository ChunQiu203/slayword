extends RefCounted
class_name StarChartHelper

# Star Chart helpers — star chart state lives in Global.player_data.player_values["star_chart"]
# star_chart is an Array[int] of length 6, one per House (0=Dawn, 1=Noon, 2=Dusk, 3=Night, 4=Wisdom, 5=Fate)

static func get_star_chart() -> Array:
	var arr: Variant = Global.player_data.player_values.get("star_chart", [])
	if typeof(arr) != TYPE_ARRAY or (arr as Array).size() != 6:
		arr = [0, 0, 0, 0, 0, 0]
		Global.player_data.player_values["star_chart"] = arr
	return arr as Array

static func get_star_count(house: int) -> int:
	var chart: Array = get_star_chart()
	return int(chart[clamp(house, 0, 5)])

static func get_total_stars() -> int:
	var chart: Array = get_star_chart()
	var total: int = 0
	for c in chart:
		total += int(c)
	return total

static func place_star(house: int) -> void:
	var chart: Array = get_star_chart()
	var h: int = clamp(house, 0, 5)
	chart[h] = int(chart[h]) + 1
	Signals.star_placed.emit(h)

static func consume_stars(house: int, count: int) -> int:
	var chart: Array = get_star_chart()
	var h: int = clamp(house, 0, 5)
	var available: int = int(chart[h])
	var taken: int = mini(count, available)
	chart[h] = available - taken
	if taken > 0:
		Signals.star_consumed.emit(h, taken)
	return taken

static func rotate_stars() -> void:
	var chart: Array = get_star_chart()
	var last: int = int(chart[5])
	for i in range(5, 0, -1):
		chart[i] = int(chart[i - 1])
	chart[0] = last
	Signals.stars_rotated.emit()

static func check_eclipse() -> bool:
	var chart: Array = get_star_chart()
	for c in chart:
		if int(c) < 1:
			return false
	return true

static func trigger_eclipse() -> int:
	var chart: Array = get_star_chart()
	var total: int = 0
	for i in range(6):
		total += int(chart[i])
		chart[i] = 0
	Signals.eclipse_triggered.emit(total)
	return total

# House bonuses (passive, applied when star exists in that house)
static func get_house_passive_bonus() -> Dictionary:
	var chart: Array = get_star_chart()
	return {
		"bonus_energy": 1 if int(chart[0]) > 0 else 0,      # House of Dawn
		"bonus_damage": 2 if int(chart[1]) > 0 else 0,       # House of Noon
		"bonus_block": 2 if int(chart[2]) > 0 else 0,        # House of Dusk
		"bonus_draw": 1 if int(chart[3]) > 0 else 0,         # House of Night
		"bonus_duplicate": int(chart[4]) > 0,                # House of Wisdom
		"bonus_random": int(chart[5]) > 0,                   # House of Fate
	}
