extends BaseStatusEffect
## If player would die, instead heal to 1 HP and consume all Stars. Once per combat.

func _connect_signals() -> void:
	super()
	if not Signals.player_health_changed.is_connected(_on_health_changed):
		Signals.player_health_changed.connect(_on_health_changed)

func _on_health_changed(_old: int, new_health: int) -> void:
	if new_health <= 0 and status_charges > 0:
		var player := Global.get_player()
		if player != null:
			# Consume all Stars directly (not via eclipse — stars ARE consumed here as life cost)
			var chart: Array = StarChartHelper.get_star_chart()
			var total: int = 0
			for i in range(6):
				total += int(chart[i])
				chart[i] = 0
			if total > 0:
				Signals.eclipse_triggered.emit(total)
			# Heal to 1 HP (set health directly)
			Global.player_data.player_health = 1
			Signals.player_health_changed.emit(0, 1)
			# Use up this effect
			status_charges = 0
			parent_combatant.remove_status_effect(status_effect_data)
