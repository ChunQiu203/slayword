extends BaseArtifact
## The Astrologer's starting relic. Places 2 Stars at combat start,
## applies Star Chart passive status. Auto-triggers alignment when
## a House reaches 2+ Stars (waterline). Also triggers Eclipse
## once per cycle when 4+ houses have Stars.

const ALIGNMENT_CARDS: Array[String] = [
	"card_astrology_dawn_blessing",
	"card_astrology_noon_fury",
	"card_astrology_dusk_guard",
	"card_astrology_night_whisper",
	"card_astrology_wisdom_insight",
	"card_astrology_fate_decree",
]

var _star_chart_ui: StarChartUI = null
var _star_bonus_ui: StarBonusUI = null
var _eclipse_triggered_this_cycle: bool = false
var _alignment_triggered: Array[bool] = [false, false, false, false, false, false]

func connect_signals() -> void:
	super()
	print("[Astrolabe] connect_signals called")
	Signals.combat_started.connect(_on_combat_started_astro)
	Signals.player_turn_started.connect(_on_first_turn_setup)
	Signals.star_placed.connect(_on_star_placed_auto_alignment)
	Signals.star_consumed.connect(_on_star_consumed)
	print("[Astrolabe] connect_signals done")

func _on_combat_started_astro(_event_id: String) -> void:
	_eclipse_triggered_this_cycle = false
	_alignment_triggered = [false, false, false, false, false, false]
	# Create UI before placing stars so icons show immediately
	var player := Global.get_player()
	if player != null:
		if _star_chart_ui == null:
			_star_chart_ui = StarChartUI.new()
			player.custom_ui_container.add_child(_star_chart_ui)
			_star_chart_ui.init("custom_ui_star_chart", player)
		if _star_bonus_ui == null:
			_star_bonus_ui = StarBonusUI.new()
			player.custom_ui_container.add_child(_star_bonus_ui)
			_star_bonus_ui.init("custom_ui_star_bonus", player)
	# Place 2 random stars
	var rng: RandomNumberGenerator = Global.player_data.get_player_rng("rng_brass_astrolabe")
	for _i in range(2):
		StarChartHelper.place_star(rng.randi_range(0, 5))
	_evaluate_star_conditions()

func _on_star_placed_auto_alignment(house: int) -> void:
	print("[Astrolabe] _on_star_placed_auto_alignment house=%d" % house)
	if house < 0 or house > 5:
		return
	var count := StarChartHelper.get_star_count(house)
	print("[Astrolabe] count=%d triggered=%s" % [count, _alignment_triggered[house]])
	if count >= 2 and not _alignment_triggered[house]:
		print("[Astrolabe] condition met, calling _add_alignment_card")
		_alignment_triggered[house] = true
		_add_alignment_card(house)
	_evaluate_star_conditions()

func _add_alignment_card(house: int) -> void:
	if house < 0 or house >= ALIGNMENT_CARDS.size():
		print("[Astrolabe] _add_alignment_card: invalid house %d" % house)
		return
	var card_object_id: String = ALIGNMENT_CARDS[house]
	print("[Astrolabe] _add_alignment_card house=%d id=%s" % [house, card_object_id])
	var card_data: CardData = Global.get_card_data(card_object_id)
	print("[Astrolabe] card_data=%s" % card_data)
	if card_data == null:
		print("[Astrolabe] card_data is NULL for %s!" % card_object_id)
		return
	var new_card: CardData = card_data.get_prototype(true)
	print("[Astrolabe] new_card=%s emitting..." % new_card)
	new_card.set_card_energy_cost_until_played(0)
	var cards: Array[CardData] = [new_card]
	Signals.card_add_to_hand_requested.emit(cards, PlayerData.PLAYER_DEFAULT_HAND_CARD_COUNT_MAX)
	Signals.alignment_triggered.emit(house, StarChartHelper.get_star_count(house))
	print("[Astrolabe] done emit")

func _on_first_turn_setup() -> void:
	var player := Global.get_player()
	if player == null:
		return
	if player.get_status_charges("status_effect_star_chart_passives") == 0:
		player.add_status_effect_charges("status_effect_star_chart_passives", 1)
	# UI already created in _on_combat_started_astro, just set reference
	if _star_chart_ui != null:
		Global.player_data.player_values["_star_chart_ui_ref"] = _star_chart_ui

func _evaluate_star_conditions() -> void:
	if not _eclipse_triggered_this_cycle and StarChartHelper.check_eclipse():
		_eclipse_triggered_this_cycle = true
		StarChartHelper.trigger_eclipse()
	if Global.player_data.player_values.get("_has_grand_cross", false):
		_check_grand_cross()

func _on_player_turn_ended() -> void:
	super()
	_evaluate_star_conditions()

func _on_star_consumed(_house: int, _count: int) -> void:
	if _eclipse_triggered_this_cycle and not StarChartHelper.check_eclipse():
		_eclipse_triggered_this_cycle = false
	if _house >= 0 and _house < 6:
		if StarChartHelper.get_star_count(_house) < 2:
			_alignment_triggered[_house] = false

func _on_combat_ended() -> void:
	super()
	_star_chart_ui = null
	_star_bonus_ui = null

func _check_grand_cross() -> void:
	var chart := StarChartHelper.get_star_chart()
	var pairs := 0
	for i in range(3):
		if int(chart[i]) > 0 and int(chart[i + 3]) > 0:
			pairs += 1
	if pairs >= 2:
		var card_data: CardData = Global.get_card_data_from_prototype("card_astrology_grand_cross_judgment")
		if card_data != null:
			var new_card: CardData = card_data.get_prototype(true)
			new_card.set_card_energy_cost_until_played(0)
			Signals.card_add_to_hand_requested.emit([new_card], PlayerData.PLAYER_DEFAULT_HAND_CARD_COUNT_MAX)
		for i in range(3):
			if int(chart[i]) > 0 and int(chart[i + 3]) > 0:
				StarChartHelper.consume_stars(i, 1)
				StarChartHelper.consume_stars(i + 3, 1)
