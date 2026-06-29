# provides a general interface for a button like object in a shop
# given a PurchaseItemAction which it populates data from
extends PanelContainer
class_name BaseShopButton

@onready var price_label: Label = $VBox/PriceLabel

var action_on_click: BaseAction = null

func init(_action_on_click: BaseAction) -> void:
	action_on_click = _action_on_click
	if price_label == null:
		price_label = get_node_or_null("VBox/PriceLabel") as Label
	if price_label == null:
		return

	var price: int = action_on_click.get_action_value("money_amount", 0)
	var can_afford := price <= Global.player_data.player_money

	price_label.text = "$%d" % price
	price_label.visible = true
	price_label.add_theme_font_size_override("font_size", 17)
	price_label.add_theme_color_override("font_color", SlayMobileStyle.TEXT_MAIN if can_afford else SlayMobileStyle.TEXT_WARN)
	price_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	price_label.add_theme_constant_override("outline_size", 3)
	price_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	price_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


func _on_button_up():
	if action_on_click != null:
		ActionHandler.add_action(action_on_click)
