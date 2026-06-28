extends BaseAction
## Set a key-value pair on Global.player_data.player_values. Used by Star Chart Power cards.

func perform_action():
	var empty_targets: Array[BaseCombatant] = []
	var action_interceptor_processors: Array[ActionInterceptorProcessor] = _intercept_action(empty_targets)
	for aip in action_interceptor_processors:
		var key: String = aip.get_shadowed_action_values("player_value_key", "")
		var value = aip.get_shadowed_action_values("player_value_value", 0)
		if key != "":
			Global.player_data.player_values[key] = value

func is_action_async() -> bool:
	return false
