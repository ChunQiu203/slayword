extends BaseRewardButton

const MONEY_REWARD_TEXTURE_PATH: String = "external/sprites/ui/ui_money_icon.svg"

func init(_action_on_click: BaseAction, _reward_group: int) -> void:
	super(_action_on_click, _reward_group)
	
	text = I18N.tr_key("card_reward.money", [_action_on_click.values.get("money_amount", 0)])
	icon = FileLoader.load_texture(MONEY_REWARD_TEXTURE_PATH)
	tooltip_text = text
