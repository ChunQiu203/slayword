extends BaseActionInterceptor
## House of Dusk passive: +4 block from all skills when a Star is present.
## Saturn's Ring artifact: +2 extra block per Star in Dusk.

func process_action_interception(processor: ActionInterceptorProcessor, _preview_mode: bool = false) -> int:
	var bonuses := StarChartHelper.get_house_passive_bonus()
	var bonus_block: int = int(bonuses.get("bonus_block", 0))
	# Saturn's Ring: extra +2 per star in Dusk
	if Global.player_data.player_values.get("_saturn_ring_active", false):
		var dusk_stars: int = StarChartHelper.get_star_count(2)
		bonus_block += dusk_stars * 2
	if bonus_block > 0:
		var block: int = processor.get_shadowed_action_values("block", 0)
		processor.shadowed_action_values["block"] = block + bonus_block
	return ACTION_ACCEPTENCES.CONTINUE
