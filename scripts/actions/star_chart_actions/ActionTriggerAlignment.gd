extends BaseAction
## Trigger the Alignment effect for a specific House.

func perform_action():
	var empty_targets: Array[BaseCombatant] = []
	var action_interceptor_processors: Array[ActionInterceptorProcessor] = _intercept_action(empty_targets)
	for aip in action_interceptor_processors:
		var house: int = aip.get_shadowed_action_values("star_house", 0)
		var stars := StarChartHelper.get_star_count(house)
		if stars < 2:
			return
		Signals.alignment_triggered.emit(house, stars)
		match house:
			0:  # Dawn - double energy
				Global.player_data.player_energy += 2
				Signals.energy_added.emit(2)
			1:  # Noon - damage all enemies
				var dmg := stars * 3
				var enemies := Global.get_tree().get_nodes_in_group("enemies")
				for enemy in enemies:
					if enemy.is_alive():
						enemy.damage(dmg, false)
			2:  # Dusk - gain block
				var blk := stars * 2
				Global.player_data.player_block += blk
				Signals.combatant_block_added.emit(Global.get_player())
			3:  # Night - draw
				Signals.card_draw_requested.emit(stars, Global.player_data.PLAYER_DEFAULT_HAND_CARD_COUNT_MAX)
			4:  # Wisdom - upgrade random card
				var hand := Global.player_data.player_hand.duplicate()
				if not hand.is_empty():
					hand.shuffle()
					for card in hand:
						if card.card_upgrade_amount < card.card_upgrade_amount_max:
							card.upgrade_card()
							break
			5:  # Fate - random bonus
				var r := randi() % 4
				match r:
					0: Global.player_data.player_energy += 1; Signals.energy_added.emit(1)
					1:
						var enemies2 := Global.get_tree().get_nodes_in_group("enemies")
						for enemy in enemies2:
							if enemy.is_alive():
								enemy.damage(stars * 2, false)
					2:
						Global.player_data.player_block += stars * 2
						Signals.combatant_block_added.emit(Global.get_player())
					3: Signals.card_draw_requested.emit(stars, Global.player_data.PLAYER_DEFAULT_HAND_CARD_COUNT_MAX)

func is_action_async() -> bool:
	return false
