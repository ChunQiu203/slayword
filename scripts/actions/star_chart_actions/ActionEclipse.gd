extends BaseAction
## Trigger Eclipse: consume all Stars, gain energy + draw + damage based on total stars consumed.

func perform_action():
	var empty_targets: Array[BaseCombatant] = []
	var action_interceptor_processors: Array[ActionInterceptorProcessor] = _intercept_action(empty_targets)
	for aip in action_interceptor_processors:
		var total := StarChartHelper.trigger_eclipse()
		if total > 0:
			var energy_gain: int = aip.get_shadowed_action_values("eclipse_energy", 2)
			var draw_count: int = aip.get_shadowed_action_values("eclipse_draw", 5)
			var damage: int = aip.get_shadowed_action_values("eclipse_damage", 0)
			# Gain energy
			Global.player_data.player_energy += energy_gain
			Signals.energy_added.emit(energy_gain)
			# Draw cards
			Signals.card_draw_requested.emit(draw_count, Global.player_data.PLAYER_DEFAULT_HAND_CARD_COUNT_MAX)
			# Deal damage to all enemies
			if damage > 0:
				var actual_damage := damage * (total / 6) if total >= 6 else 0
				if actual_damage > 0:
					var enemies := Global.get_tree().get_nodes_in_group("enemies")
					for enemy in enemies:
						if enemy.is_alive():
							enemy.damage(actual_damage, true)

func is_action_async() -> bool:
	return false
