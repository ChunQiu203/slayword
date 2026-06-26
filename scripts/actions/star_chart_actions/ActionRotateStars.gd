extends BaseAction
## Rotate all Stars clockwise (or counter-clockwise) through the Houses.

func perform_action():
	var empty_targets: Array[BaseCombatant] = []
	var action_interceptor_processors: Array[ActionInterceptorProcessor] = _intercept_action(empty_targets)
	for aip in action_interceptor_processors:
		var direction: int = aip.get_shadowed_action_values("rotate_direction", 1)
		var times: int = aip.get_shadowed_action_values("rotate_times", 1)
		for _t in range(times):
			if direction >= 0:
				StarChartHelper.rotate_stars()
			else:
				# Counter-clockwise: reverse rotation
				var chart = StarChartHelper.get_star_chart()
				var first := int(chart[0])
				for i in range(5):
					chart[i] = int(chart[i + 1])
				chart[5] = first
				Signals.stars_rotated.emit()

func is_action_async() -> bool:
	return false
