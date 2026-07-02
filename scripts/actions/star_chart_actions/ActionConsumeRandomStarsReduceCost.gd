extends BaseAction
## Consume up to max_stars random Stars from any House.
## Cost reduction is handled by ListenerStarCostReducer.

@export var max_stars: int = 3

func perform_action() -> void:
	var empty_targets: Array[BaseCombatant] = []
	var action_interceptor_processors: Array[ActionInterceptorProcessor] = _intercept_action(empty_targets)
	for aip in action_interceptor_processors:
		var consume_max: int = aip.get_shadowed_action_values("max_stars", max_stars)
		var consumed := 0
		var chart: Array = StarChartHelper.get_star_chart()
		var houses_with_stars: Array[int] = []
		for i in range(6):
			if int(chart[i]) > 0:
				houses_with_stars.append(i)
		while consumed < consume_max and houses_with_stars.size() > 0:
			var random_idx: int = randi() % houses_with_stars.size()
			var house: int = houses_with_stars[random_idx]
			var result: int = StarChartHelper.consume_stars(house, 1)
			if result > 0:
				consumed += 1
				if StarChartHelper.get_star_count(house) <= 0:
					houses_with_stars.erase(house)
			else:
				houses_with_stars.erase(house)
		Global.player_data.player_values["_star_consumed_count"] = consumed

func is_action_async() -> bool:
	return false
