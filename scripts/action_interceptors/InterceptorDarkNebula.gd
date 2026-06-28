extends BaseActionInterceptor
## Dark Nebula: When a Star is consumed, deal damage to a random enemy.

func process_action_interception(processor: ActionInterceptorProcessor, _preview_mode: bool = false) -> int:
	var parent_combatant: BaseCombatant = processor.parent_action.parent_combatant
	if parent_combatant == null:
		return ACTION_ACCEPTENCES.CONTINUE
	var charges: int = parent_combatant.get_status_charges("status_effect_dark_nebula")
	if charges <= 0:
		return ACTION_ACCEPTENCES.CONTINUE
	var count: int = processor.get_shadowed_action_values("star_count", 0)
	var damage: int = count * 3 * charges
	if damage > 0:
		var enemies := Global.get_tree().get_nodes_in_group("enemies")
		var alive_enemies: Array = []
		for e in enemies:
			if e.is_alive():
				alive_enemies.append(e)
		if not alive_enemies.is_empty():
			var target: BaseCombatant = alive_enemies[randi() % alive_enemies.size()]
			target.damage(damage, false)
	return ACTION_ACCEPTENCES.CONTINUE
