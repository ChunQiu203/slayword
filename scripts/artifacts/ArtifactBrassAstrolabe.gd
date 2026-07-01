extends BaseArtifact
## The Astrologer's starting relic. Places 2 Stars at combat start,
## applies Star Chart passive status. Stars rotate clockwise each turn.

var _star_chart_ui: StarChartUI = null
var _star_bonus_ui: StarBonusUI = null

func connect_signals() -> void:
	super()
	Signals.combat_started.connect(_on_combat_started_astro)
	Signals.player_turn_started.connect(_on_first_turn_setup)

func _on_combat_started_astro(_event_id: String) -> void:
	# Place 2 initial Stars in random Houses
	var rng: RandomNumberGenerator = Global.player_data.get_player_rng("rng_brass_astrolabe")
	for _i in range(2):
		StarChartHelper.place_star(rng.randi_range(0, 5))

func _on_first_turn_setup() -> void:
	# Apply status effect AFTER clear_all_status_effects() has run
	var player := Global.get_player()
	if player == null:
		return
	# Only add if not already present
	if player.get_status_charges("status_effect_star_chart_passives") == 0:
		player.add_status_effect_charges("status_effect_star_chart_passives", 1)
	# Register Star Chart UI
	if _star_chart_ui == null:
		_star_chart_ui = StarChartUI.new()
		player.custom_ui_container.add_child(_star_chart_ui)
		_star_chart_ui.init("custom_ui_star_chart", player)
	Global.player_data.player_values["_star_chart_ui_ref"] = _star_chart_ui
	# Register Star Bonus UI
	if _star_bonus_ui == null:
		_star_bonus_ui = StarBonusUI.new()
		player.custom_ui_container.add_child(_star_bonus_ui)
		_star_bonus_ui.init("custom_ui_star_bonus", player)

func _on_player_turn_ended() -> void:
	super()
	# Check for Grand Cross
	if Global.player_data.player_values.get("_has_grand_cross", false):
		_check_grand_cross()
	# Check for Eclipse
	if StarChartHelper.check_eclipse():
		StarChartHelper.trigger_eclipse()

func _on_combat_ended() -> void:
	super()
	_star_chart_ui = null
	_star_bonus_ui = null

func _check_grand_cross() -> void:
	var chart := StarChartHelper.get_star_chart()
	# Check opposite pairs: 0-3, 1-4, 2-5
	var pairs := 0
	for i in range(3):
		if int(chart[i]) > 0 and int(chart[i + 3]) > 0:
			pairs += 1
	if pairs >= 2:  # At least 2 opposite pairs
		# Add Grand Cross Judgment card to hand
		var card_data: CardData = Global.get_card_data_from_prototype("card_astrology_grand_cross_judgment")
		if card_data != null:
			var new_card: CardData = card_data.get_prototype(true)
			new_card.set_card_energy_cost_until_played(0)
			Signals.card_add_to_hand_requested.emit([new_card], PlayerData.PLAYER_DEFAULT_HAND_CARD_COUNT_MAX)
		# Consume 1 star from each paired house
		for i in range(3):
			if int(chart[i]) > 0 and int(chart[i + 3]) > 0:
				StarChartHelper.consume_stars(i, 1)
				StarChartHelper.consume_stars(i + 3, 1)
