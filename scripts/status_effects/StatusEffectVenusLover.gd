extends BaseStatusEffect
## Venus, the Lover: Gain 3 Block at start of turn while a Star is in House of Dusk.

func _connect_signals() -> void:
	super()
	if not Signals.player_turn_started.is_connected(_on_player_turn_start):
		Signals.player_turn_started.connect(_on_player_turn_start)

func _on_player_turn_start() -> void:
	if StarChartHelper.get_star_count(2) > 0:  # House of Dusk
		Global.player_data.player_block += 3
		Signals.combatant_block_added.emit(Global.get_player())
