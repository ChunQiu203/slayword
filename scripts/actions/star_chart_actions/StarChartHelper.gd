extends RefCounted
class_name StarChartHelper

# Star Chart helpers — star chart state lives in Global.player_data.player_values["star_chart"]
# star_chart is an Array[int] of length 6, one per House (0=Dawn, 1=Noon, 2=Dusk, 3=Night, 4=Wisdom, 5=Fate)

static func get_star_chart() -> Array:
	var arr: Variant = Global.player_data.player_values.get("star_chart", null)
	if arr == null or typeof(arr) != TYPE_ARRAY or (arr as Array).size() != 6:
		arr = [0, 0, 0, 0, 0, 0]
		Global.player_data.player_values["star_chart"] = arr
		print("[StarChart] get_star_chart: initialized new chart")
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
	print("[StarChart] place_star house=%d -> chart=%s" % [h, chart])
	Signals.star_placed.emit(h)

static func consume_stars(house: int, count: int) -> int:
	var chart: Array = get_star_chart()
	var h: int = clamp(house, 0, 5)
	var available: int = int(chart[h])
	var taken: int = mini(count, available)
	chart[h] = available - taken
	print("[StarChart] consume_stars house=%d count=%d taken=%d -> chart=%s" % [h, count, taken, chart])
	if taken > 0:
		Signals.star_consumed.emit(h, taken)
	return taken

static func check_eclipse() -> bool:
	var chart: Array = get_star_chart()
	var houses_with_stars: int = 0
	for c in chart:
		if int(c) >= 1:
			houses_with_stars += 1
	print("[StarChart] check_eclipse: houses_with_stars=%d chart=%s" % [houses_with_stars, chart])
	return houses_with_stars >= 4

static func trigger_eclipse() -> int:
	var chart: Array = get_star_chart()
	var total: int = get_total_stars()
	print("[StarChart] ECLIPSE triggered! total_stars=%d chart=%s" % [total, chart])
	Signals.eclipse_triggered.emit(total)
	if total > 0:
		# Add Eclipse Burst card to hand via signal so Hand UI creates a Card node
		var card_data: CardData = Global.get_card_data_from_prototype("card_astrology_eclipse_burst")
		if card_data != null:
			var new_card: CardData = card_data.get_prototype(true)
			new_card.set_card_energy_cost_until_played(0)
			Signals.card_add_to_hand_requested.emit([new_card], PlayerData.PLAYER_DEFAULT_HAND_CARD_COUNT_MAX)
	return total

static func get_house_passive_bonus() -> Dictionary:
	var chart: Array = get_star_chart()
	var has_singularity: bool = false
	if get_total_stars() == 1:
		var player := Global.get_player()
		if player != null and player.get_status_charges("status_effect_singularity") > 0:
			has_singularity = true
	var m_e: int = 3 if (has_singularity and int(chart[0]) > 0) else 1
	var m_d: int = 3 if (has_singularity and int(chart[1]) > 0) else 1
	var m_k: int = 3 if (has_singularity and int(chart[2]) > 0) else 1
	var m_n: int = 3 if (has_singularity and int(chart[3]) > 0) else 1
	return {
		"bonus_energy": m_e if int(chart[0]) > 0 else 0,
		"bonus_damage": 2 * m_d if int(chart[1]) > 0 else 0,
		"bonus_block": 2 * m_k if int(chart[2]) > 0 else 0,
		"bonus_draw": m_n if int(chart[3]) > 0 else 0,
		"bonus_duplicate": int(chart[4]) > 0,
		"bonus_random": int(chart[5]) > 0,
	}
