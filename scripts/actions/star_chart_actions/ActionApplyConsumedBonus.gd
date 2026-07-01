extends BaseAction
## Read _star_consumed_count (set by ActionConsumeStar) and add consumed * bonus_per_star
## to damage and/or block values via the interceptor processor shadowing.
## Use in card JSON after ActionConsumeStar to scale effects by stars consumed.
## Parameters:
##   bonus_damage_per_star: int (default 0) — extra damage per star consumed
##   bonus_block_per_star: int (default 0) — extra block per star consumed

func perform_action():
	var empty_targets: Array[BaseCombatant] = []
	var action_interceptor_processors: Array[ActionInterceptorProcessor] = _intercept_action(empty_targets)
	var consumed: int = int(Global.player_data.player_values.get("_star_consumed_count", 0))
	if consumed <= 0:
		return
	for aip in action_interceptor_processors:
		var bonus_dmg: int = int(aip.get_shadowed_action_values("bonus_damage_per_star", 0))
		var bonus_blk: int = int(aip.get_shadowed_action_values("bonus_block_per_star", 0))
		if bonus_dmg > 0:
			var old_damage: int = int(aip.get_shadowed_action_values("damage", 0))
			aip.shadowed_action_values["damage"] = old_damage + bonus_dmg * consumed
		if bonus_blk > 0:
			var old_block: int = int(aip.get_shadowed_action_values("block", 0))
			aip.shadowed_action_values["block"] = old_block + bonus_blk * consumed

func is_action_async() -> bool:
	return false
