# provides a general interface for a button like object in a shop
# given a PurchaseItemAction which it populates data from
extends Control
class_name BaseShopButton

@onready var price_label: Label = $PriceLabel

var action_on_click: BaseAction = null
var _price_tag_panel: PanelContainer

func init(_action_on_click: BaseAction) -> void:
	action_on_click = _action_on_click
	if price_label == null:
		price_label = get_node_or_null("PriceLabel") as Label
	if price_label == null:
		return
	
	var price: int = action_on_click.get_action_value("money_amount", 0)
	price_label.text = "$%d" % price
	var can_afford := price <= Global.player_data.player_money
	_style_price_tag(can_afford)
	if not can_afford:
		price_label.add_theme_color_override("font_color", SlayMobileStyle.TEXT_WARN)
	else:
		price_label.add_theme_color_override("font_color", SlayMobileStyle.TEXT_MAIN)


func _style_price_tag(can_afford: bool) -> void:
	if _price_tag_panel == null:
		_price_tag_panel = get_node_or_null("PriceTag") as PanelContainer
	if _price_tag_panel == null:
		_price_tag_panel = PanelContainer.new()
		_price_tag_panel.name = "PriceTag"
		_price_tag_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_price_tag_panel)
		price_label.reparent(_price_tag_panel)
		price_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		price_label.offset_left = 0
		price_label.offset_top = 0
		price_label.offset_right = 0
		price_label.offset_bottom = 0
	_price_tag_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_price_tag_panel.add_theme_stylebox_override("panel", _price_tag_style(can_afford))
	_price_tag_panel.move_to_front()
	price_label.custom_minimum_size.y = 24
	price_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	price_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	SlayMobileStyle.style_label(price_label, 17, SlayMobileStyle.TEXT_MAIN, HORIZONTAL_ALIGNMENT_CENTER)
	call_deferred("_position_price_tag")


func _price_tag_style(can_afford: bool) -> StyleBoxFlat:
	var fill := Color(0.20, 0.12, 0.055, 0.95)
	var border := Color(0.83, 0.66, 0.32, 0.96)
	if not can_afford:
		fill = Color(0.28, 0.055, 0.045, 0.96)
		border = Color(0.95, 0.36, 0.28, 0.96)
	var sb := SlayMobileStyle.panel_style(fill, border, 5)
	sb.set_border_width_all(2)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	sb.shadow_size = 4
	sb.shadow_offset = Vector2(0, 2)
	return sb


func _position_price_tag() -> void:
	if _price_tag_panel == null:
		return
	var base_size := size
	base_size.x = maxf(base_size.x, custom_minimum_size.x)
	base_size.y = maxf(base_size.y, custom_minimum_size.y)
	var tag_size := Vector2(92.0, 28.0)
	if base_size.x <= 160.0:
		tag_size.x = 82.0
	_price_tag_panel.size = tag_size
	_price_tag_panel.position = Vector2(
		maxf((base_size.x - tag_size.x) * 0.5, 0.0),
		maxf(base_size.y - tag_size.y - 2.0, 0.0)
	)


func _on_button_up():
	if action_on_click != null:
		ActionHandler.add_action(action_on_click)
