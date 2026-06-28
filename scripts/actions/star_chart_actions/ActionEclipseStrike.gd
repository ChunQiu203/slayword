extends BaseAction
## Eclipse Strike: Deal base damage. If 4+ Stars, consume all Stars for bonus damage.

func perform_action():
	var empty_targets: Array[BaseCombatant] = []
	var action_interceptor_processors: Array[ActionInterceptorProcessor] = _intercept_action(empty_targets)
	for aip in action_interceptor_processors:
		var base_damage: int = aip.get_shadowed_action_values("damage", 20)
		var bonus_damage: int = aip.get_shadowed_action_values("bonus_damage", 15)
		var min_stars: int = aip.get_shadowed_action_values("min_stars", 4)
		
		var total_stars := StarChartHelper.get_total_stars()
		var final_damage := base_damage
		
		if total_stars >= min_stars:
			var consumed := StarChartHelper.trigger_eclipse()
			if consumed > 0:
				final_damage += bonus_damage
		
		var delay: float = aip.get_shadowed_action_values("time_delay", 0.25)
		var target_override: int = aip.get_shadowed_action_values("target_override", BaseAction.TARGET_OVERRIDES.SELECTED_TARGETS)
		
		if parent_combatant != null:
			parent_combatant.play_attack_animation()
		
		var action_data: Array[Dictionary] = [{Scripts.ACTION_ATTACK: {"damage": final_damage, "time_delay": delay, "target_override": target_override}}]
		var attack_actions: Array[BaseAction] = ActionGenerator.create_actions(parent_combatant, card_play_request, targets, action_data, self)
		ActionHandler.add_actions(attack_actions)

func is_action_async() -> bool:
	return false
