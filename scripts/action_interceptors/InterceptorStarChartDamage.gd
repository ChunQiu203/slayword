extends BaseActionInterceptor
## House of Noon passive: +4 damage to all attacks when a Star is present.

func process_action_interception(processor: ActionInterceptorProcessor, _preview_mode: bool = false) -> int:
	var bonuses := StarChartHelper.get_house_passive_bonus()
	var bonus_damage: int = int(bonuses.get("bonus_damage", 0))
	var old_damage: int = processor.get_shadowed_action_values("damage", 0)
	print("[StarInterceptor] bonus_damage=%d old_damage=%d" % [bonus_damage, old_damage])
	if bonus_damage > 0:
		processor.shadowed_action_values["damage"] = old_damage + bonus_damage
		print("[StarInterceptor] new_damage=%d" % (old_damage + bonus_damage))
	return ACTION_ACCEPTENCES.CONTINUE
