# Overlay for a shop
extends Control

const SHOP_FOREGROUND_DECOR := preload("res://scripts/ui/shop/ShopForegroundDecor.gd")

@onready var card_container: HBoxContainer = $CardContainer
@onready var artifact_container: VBoxContainer = $ArtifactContainer
@onready var consumable_container: VBoxContainer = $ConsumableContainer

@onready var continue_button: Button = $ContinueButton

@onready var map = $%Map
var _shop_panels: Dictionary[String, Control] = {}
var _shop_tab_buttons: Dictionary[String, Button] = {}
var _active_shop_tab: String = "cards"
var _shop_title_label: Label
var _shop_money_label: Label
var _shop_hint_label: Label
var _shop_section_titles: Dictionary[String, Label] = {}
var _card_item_parent: Container
var _artifact_item_parent: Container
var _consumable_item_parent: Container

func _ready():
	_build_mobile_layout()
	I18N.locale_changed.connect(_on_locale_changed)
	Signals.player_money_changed.connect(_refresh_money_label)

	Signals.combat_started.connect(_on_combat_started)
	
	Signals.map_location_selected.connect(_on_map_location_selected)
	Signals.shop_opened.connect(_on_shop_opened)
	
	Signals.card_purchased.connect(_on_card_purchased)
	Signals.artifact_purchased.connect(_on_artifact_purchased)
	Signals.consumable_purchased.connect(_on_consumable_purchased)

	for legacy in continue_button.get_children():
		if legacy.name == "LocalizedTextLabel":
			legacy.queue_free()
	continue_button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	SlayMobileStyle.style_button(continue_button, "red", 22)
	continue_button.pressed.connect(_on_continue_button_up)
	_apply_shop_text()

func _on_locale_changed(_locale: String) -> void:
	_apply_shop_text()
	if visible:
		populate_shop()

func _build_mobile_layout() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var bg: ColorRect = get_node_or_null("Background") as ColorRect
	if bg:
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		bg.offset_left = 0
		bg.offset_top = 0
		bg.offset_right = 0
		bg.offset_bottom = 0
		bg.color = Color(0, 0, 0, 0.30)
	var shop_bg: TextureRect = get_node_or_null("Background2") as TextureRect
	if shop_bg:
		shop_bg.visible = true
		shop_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		shop_bg.offset_left = 0
		shop_bg.offset_top = 0
		shop_bg.offset_right = 0
		shop_bg.offset_bottom = 0
		shop_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		shop_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		shop_bg.modulate = Color(0.82, 0.86, 0.78, 0.72)

	var veil := ColorRect.new()
	veil.name = "ShopVeil"
	veil.set_anchors_preset(Control.PRESET_FULL_RECT)
	veil.color = Color(0, 0, 0, 0.34)
	veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(veil)

	var decor: ShopForegroundDecor = SHOP_FOREGROUND_DECOR.new()
	decor.name = "ShopForegroundDecor"
	decor.set_anchors_preset(Control.PRESET_FULL_RECT)
	decor.offset_left = 0
	decor.offset_top = 0
	decor.offset_right = 0
	decor.offset_bottom = 0
	decor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(decor)

	var margin := MarginContainer.new()
	margin.name = "MobileShopRoot"
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.offset_left = 28
	margin.offset_top = 22
	margin.offset_right = -28
	margin.offset_bottom = -22
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 9)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	margin.add_child(root)

	var header_panel := PanelContainer.new()
	header_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_panel.add_theme_stylebox_override("panel", SlayMobileStyle.panel_style(Color(0.038, 0.043, 0.039, 0.72), SlayMobileStyle.BORDER_GOLD, 8))
	root.add_child(header_panel)

	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 14)
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	header_panel.add_child(header)

	var header_text := VBoxContainer.new()
	header_text.add_theme_constant_override("separation", 2)
	header_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(header_text)

	_shop_title_label = Label.new()
	_shop_title_label.name = "ShopTitle"
	_shop_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	SlayMobileStyle.style_label(_shop_title_label, 31, SlayMobileStyle.TEXT_MAIN, HORIZONTAL_ALIGNMENT_LEFT)
	header_text.add_child(_shop_title_label)

	_shop_hint_label = Label.new()
	SlayMobileStyle.style_label(_shop_hint_label, 15, SlayMobileStyle.TEXT_MUTED, HORIZONTAL_ALIGNMENT_LEFT)
	header_text.add_child(_shop_hint_label)

	_shop_money_label = Label.new()
	_shop_money_label.custom_minimum_size.x = 160
	SlayMobileStyle.style_label(_shop_money_label, 22, SlayMobileStyle.TEXT_MAIN, HORIZONTAL_ALIGNMENT_RIGHT)
	header.add_child(_shop_money_label)

	var tab_row := HBoxContainer.new()
	tab_row.add_theme_constant_override("separation", 8)
	root.add_child(tab_row)
	_add_shop_tab(tab_row, "cards", "shop.tab.cards")
	_add_shop_tab(tab_row, "artifacts", "shop.tab.artifacts")
	_add_shop_tab(tab_row, "consumables", "shop.tab.consumables")

	var board := PanelContainer.new()
	board.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	board.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board.add_theme_stylebox_override("panel", SlayMobileStyle.panel_style(Color(0.040, 0.049, 0.043, 0.80), SlayMobileStyle.BORDER_GOLD, 8))
	root.add_child(board)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 10)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	board.add_child(content)

	_shop_panels["cards"] = _make_card_shop_section(content, "shop.tab.cards", card_container)
	card_container.add_theme_constant_override("separation", 18)
	card_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_container.custom_minimum_size.y = 330
	_card_item_parent = card_container
	_shop_panels["artifacts"] = _make_grid_shop_section(content, "shop.tab.artifacts", artifact_container, "artifacts")
	_shop_panels["consumables"] = _make_grid_shop_section(content, "shop.tab.consumables", consumable_container, "consumables")

	var action_row := HBoxContainer.new()
	action_row.alignment = BoxContainer.ALIGNMENT_END
	action_row.add_theme_constant_override("separation", 12)
	root.add_child(action_row)
	continue_button.reparent(action_row)
	continue_button.custom_minimum_size = Vector2(260, SlayMobileStyle.TOUCH_H)
	_show_shop_tab(_active_shop_tab)


func _add_shop_tab(parent: HBoxContainer, tab_id: String, key: String) -> void:
	var btn := Button.new()
	btn.text = I18N.tr_key(key)
	btn.toggle_mode = true
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.pressed.connect(_show_shop_tab.bind(tab_id))
	SlayMobileStyle.style_button(btn, "dark", 18)
	parent.add_child(btn)
	_shop_tab_buttons[tab_id] = btn


func _make_card_shop_section(parent: Node, title_key: String, content_node: Control) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _shelf_panel_style())
	parent.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(box)
	var label := Label.new()
	label.name = "SectionTitle"
	label.text = I18N.tr_key(title_key)
	SlayMobileStyle.style_label(label, 22, SlayMobileStyle.TEXT_MAIN, HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(label)
	_shop_section_titles["cards"] = label

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size.y = 354
	box.add_child(scroll)
	content_node.reparent(scroll)
	content_node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_node.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return panel


func _make_grid_shop_section(parent: Node, title_key: String, content_node: VBoxContainer, tab_id: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", _shelf_panel_style())
	parent.add_child(panel)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(box)

	var label := Label.new()
	label.name = "SectionTitle"
	label.text = I18N.tr_key(title_key)
	SlayMobileStyle.style_label(label, 22, SlayMobileStyle.TEXT_MAIN, HORIZONTAL_ALIGNMENT_CENTER)
	box.add_child(label)
	_shop_section_titles[tab_id] = label

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(scroll)

	content_node.reparent(scroll)
	content_node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_node.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_node.add_theme_constant_override("separation", 8)

	var grid := GridContainer.new()
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 12)
	content_node.add_child(grid)

	if tab_id == "artifacts":
		_artifact_item_parent = grid
	else:
		_consumable_item_parent = grid
	return panel


func _shelf_panel_style() -> StyleBoxFlat:
	var sb := SlayMobileStyle.panel_style(Color(0.018, 0.024, 0.021, 0.52), Color(0.55, 0.45, 0.25, 0.78), 7)
	sb.set_border_width_all(1)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	sb.shadow_size = 5
	sb.shadow_offset = Vector2(0, 3)
	return sb


func _show_shop_tab(tab_id: String) -> void:
	_active_shop_tab = tab_id
	for k: String in _shop_panels.keys():
		(_shop_panels[k] as Control).visible = k == tab_id
	for k: String in _shop_tab_buttons.keys():
		var btn: Button = _shop_tab_buttons[k]
		btn.set_pressed_no_signal(k == tab_id)
		SlayMobileStyle.style_button(btn, "gold" if k == tab_id else "dark", 18)


func _apply_shop_text() -> void:
	if _shop_title_label:
		_shop_title_label.text = I18N.tr_key("combat.shop")
	if _shop_hint_label:
		_shop_hint_label.text = I18N.tr_key("shop.hint")
	for k: String in _shop_tab_buttons.keys():
		var key := "shop.tab." + k
		_shop_tab_buttons[k].text = I18N.tr_key(key)
	for k: String in _shop_section_titles.keys():
		var label: Label = _shop_section_titles[k]
		if is_instance_valid(label):
			label.text = I18N.tr_key("shop.tab." + k)
	continue_button.text = I18N.tr_key("shop.leave")
	_refresh_money_label()


func _refresh_money_label() -> void:
	if _shop_money_label:
		_shop_money_label.text = I18N.tr_key("menu.money_prefix", [Global.player_data.player_money])

func populate_shop() -> void:
	clear_shop()
	_refresh_money_label()
	
	var shop_data: ShopData = Global.get_shop_at_player_location()
	if shop_data == null:
		shop_data = Global.generate_shop_at_player_location()

	if shop_data != null:
		shop_data.visit_shop()	# ensure the shop is populated
		
		### populate shop cards
		var shop_cards: Array[CardData] = shop_data.shop_cards
		for card_data in shop_cards:
			# create card button asset
			var card_shop_button: BaseShopButton = Scenes.CARD_SHOP_BUTTON.instantiate()
			_card_item_parent.add_child(card_shop_button)
			
			# generate action payload
			var card_price: int = shop_data.get_shop_card_price(card_data)
			
			var purchase_card_action_data: Array[Dictionary] = [
				{
				Scripts.ACTION_SHOP_PURCHASE_ITEMS: {
					"card_data": card_data,
					"money_amount": card_price,
					}
				}
			]
			
			var purchase_card_action: BaseAction = ActionGenerator.create_actions(null, null, [], purchase_card_action_data, null)[0]
			
			# initialize button with payload
			card_shop_button.init(purchase_card_action)
		
		### populate shop artifacts
		var shop_artifacts: Array[ArtifactData] = shop_data.get_shop_artifact_options()
		for artifact_data in shop_artifacts:
			# create artifact button asset
			var artifact_shop_button: BaseShopButton = Scenes.ARTIFACT_SHOP_BUTTON.instantiate()
			_artifact_item_parent.add_child(artifact_shop_button)
			
			# generate action payload
			var artifact_id: String = artifact_data.object_id
			var artifact_price: int = shop_data.get_shop_artifact_price(artifact_id)
			
			var purchase_artifact_action_data: Array[Dictionary] = [
				{
				Scripts.ACTION_SHOP_PURCHASE_ITEMS: {
					"artifact_id": artifact_id,
					"money_amount": artifact_price,
					}
				}
			]
			
			var purchase_artifact_action: BaseAction = ActionGenerator.create_actions(null, null, [], purchase_artifact_action_data, null)[0]
			
			# initialize button with payload
			artifact_shop_button.init(purchase_artifact_action)
		
		### populate shop consumables
		for consumable_slot_index in shop_data.shop_consumable_slot_to_consumable_object_id.keys():
			# create consumable button asset
			var consumable_shop_button: BaseShopButton = Scenes.CONSUMABLE_SHOP_BUTTON.instantiate()
			_consumable_item_parent.add_child(consumable_shop_button)
			
			# generate action payload
			var consumable_object_id: String = shop_data.shop_consumable_slot_to_consumable_object_id[consumable_slot_index]
			var consumable_price: int = shop_data.get_shop_consumable_price(consumable_slot_index)
			
			var purchase_consumable_action_data: Array[Dictionary] = [
				{
				Scripts.ACTION_SHOP_PURCHASE_ITEMS: {
					"consumable_object_id": consumable_object_id,
					"consumable_slot_index": consumable_slot_index,
					"money_amount": consumable_price,
					}
				}
			]
			
			var purchase_consumable_action: BaseAction = ActionGenerator.create_actions(null, null, [], purchase_consumable_action_data, null)[0]
			
			# initialize button with payload
			consumable_shop_button.init(purchase_consumable_action)
	_show_shop_tab(_active_shop_tab)
		

func clear_shop():
	_clear_item_parent(_card_item_parent)
	_clear_item_parent(_artifact_item_parent)
	_clear_item_parent(_consumable_item_parent)


func _clear_item_parent(parent: Node) -> void:
	if parent == null:
		return
	for child in parent.get_children():
		child.queue_free()

func _on_combat_started(_event_id: String):
	visible = false
	clear_shop()

func _on_shop_opened():
	visible = true
	populate_shop()
	SlayMobileStyle.tween_panel_enter(self)

func _on_card_purchased(_card_data: CardData):
	_repopulate_shop_after_actions_ended()

func _on_artifact_purchased(_artifact_data: ArtifactData):
	_repopulate_shop_after_actions_ended()

func _on_consumable_purchased(_consumable_object_id: String):
	_repopulate_shop_after_actions_ended()

func _repopulate_shop_after_actions_ended() -> void:
	if ActionHandler.actions_being_performed:
		await ActionHandler.actions_ended
	populate_shop()

func _on_continue_button_up():
	# increment the act and potentially generate a new one
	if Global.is_end_of_act():
		if not Global.is_end_of_run():
			ActionGenerator.generate_next_act()
	
	if not Global.is_end_of_run():
		map.show_map()
	else:
		visible = false
		Signals.run_victory.emit()

func _on_map_location_selected(_location_data: LocationData):
	visible = false
