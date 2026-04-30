extends BaseRewardButton

const CARD_REWARD_TEXTURE_PATH: String = "external/sprites/ui/ui_deck_icon.svg"

func init(_action_on_click: BaseAction, _reward_group: int) -> void:
	super(_action_on_click, _reward_group)
	
	text = I18N.tr_key("card_reward.card")
	icon = FileLoader.load_texture(CARD_REWARD_TEXTURE_PATH)
	tooltip_text = text


func _on_button_up():
	if action_on_click != null:
		# request the player pick a card
		var pick_action: ActionBasePickCards = action_on_click # typecast
		ActionHandler.add_action(pick_action)
		
		# wait until selection made
		await pick_action.action_async_finished
		if len(pick_action.picked_cards) > 0:
			# user picked a card, remove the reward
			queue_free()
	else:
		breakpoint
		queue_free()
