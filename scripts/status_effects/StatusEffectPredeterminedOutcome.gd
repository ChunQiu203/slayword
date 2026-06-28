extends BaseStatusEffect
## When player turn ends, applies negate_damage to all enemies for the next enemy turn.

func _connect_signals() -> void:
	super()
	if not Signals.player_turn_ended.is_connected(_on_player_turn_ended):
		Signals.player_turn_ended.connect(_on_player_turn_ended)

func _on_player_turn_ended() -> void:
	var enemies := Global.get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy.is_alive():
			enemy.add_status_effect_charges("status_effect_negate_damage", 1)
	# This effect is consumed after one use
	status_charges = 0
	if parent_combatant != null:
		parent_combatant.remove_status_effect(status_effect_data)
