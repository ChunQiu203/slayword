# Test combat menu - full sandbox: pick enemy + loadout, then fight.
# Entire UI is created dynamically (no scene file dependency).
extends Control

var _enemy_container: VBoxContainer
var _card_container: VBoxContainer
var _artifact_container: VBoxContainer
var _consumable_container: VBoxContainer
var _enemy_search: LineEdit
var _card_search: LineEdit
var _artifact_search: LineEdit
var _consumable_search: LineEdit
var _selected_display: Label
var _tab_container: TabContainer
var _back_button: Button
var _fight_button: Button

var selected_enemy_id: String = ""
var selected_card_ids: Array[String] = []
var selected_artifact_ids: Array[String] = []
var selected_consumable_ids: Array[String] = []

var _all_enemies: Array = []
var _all_cards: Array = []
var _all_artifacts: Array = []
var _all_consumables: Array = []

func _ready():
	_build_ui()
	_collect_all_data()
	_refresh_enemies("")
	_refresh_cards("")
	_refresh_artifacts("")
	_refresh_consumables("")
	_update_display()
	if _tab_container:
		_tab_container.current_tab = 0
	I18N.locale_changed.connect(_on_locale_changed)

func _on_locale_changed(_locale: String):
	_refresh_all_labels()
	_collect_all_data()
	_refresh_enemies("")
	_refresh_cards("")
	_refresh_artifacts("")
	_refresh_consumables("")
	_update_display()

func _refresh_all_labels():
	if _tab_container:
		_tab_container.set_tab_title(0, I18N.tr_key("test.enemy"))
		_tab_container.set_tab_title(1, I18N.tr_key("test.cards"))
		_tab_container.set_tab_title(2, I18N.tr_key("test.artifacts"))
		_tab_container.set_tab_title(3, I18N.tr_key("test.consumables"))
	if _back_button:
		_back_button.text = I18N.tr_key("menu.back")
	if _fight_button:
		_fight_button.text = I18N.tr_key("test.fight")

# Called by TitleScreen when the menu is shown
func populate_test_menu():
	_collect_all_data()
	_refresh_enemies("")
	_refresh_cards("")
	_refresh_artifacts("")
	_refresh_consumables("")
	_update_display()
	if _tab_container:
		_tab_container.current_tab = 0

func _build_ui():
	# Root vertical layout
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	margin.anchor_right = 1.0
	margin.anchor_bottom = 1.0
	add_child(margin)
	
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)
	
	# Title
	var title := Label.new()
	title.text = I18N.tr_key("test.title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	vbox.add_child(title)
	
	# Selected display
	_selected_display = Label.new()
	_selected_display.text = I18N.tr_key("test.select_hint")
	_selected_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_selected_display.add_theme_font_size_override("font_size", 16)
	_selected_display.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
	vbox.add_child(_selected_display)
	
	# Tab container
	_tab_container = TabContainer.new()
	_tab_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tab_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tab_container.add_theme_font_size_override("font_size", 16)
	vbox.add_child(_tab_container)
	
	# Tab 1: Enemy
	var enemy_tab = _build_enemy_tab()
	_tab_container.add_child(enemy_tab)
	# Tab 2: Cards
	var card_tab = _build_card_tab()
	_tab_container.add_child(card_tab)
	# Tab 3: Artifacts
	var art_tab = _build_artifact_tab()
	_tab_container.add_child(art_tab)
	# Tab 4: Consumables
	var con_tab = _build_consumable_tab()
	_tab_container.add_child(con_tab)
	
	# Set tab titles from I18N
	_tab_container.set_tab_title(0, I18N.tr_key("test.enemy"))
	_tab_container.set_tab_title(1, I18N.tr_key("test.cards"))
	_tab_container.set_tab_title(2, I18N.tr_key("test.artifacts"))
	_tab_container.set_tab_title(3, I18N.tr_key("test.consumables"))
	
	# Bottom buttons
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 20)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(hbox)
	
	_back_button = Button.new()
	_back_button.text = I18N.tr_key("menu.back")
	_back_button.custom_minimum_size = Vector2(180, 50)
	_back_button.pressed.connect(_on_back)
	_style_button(_back_button)
	hbox.add_child(_back_button)
	
	_fight_button = Button.new()
	_fight_button.text = I18N.tr_key("test.fight")
	_fight_button.custom_minimum_size = Vector2(280, 56)
	_fight_button.pressed.connect(_on_fight)
	_style_button(_fight_button)
	_fight_button.add_theme_color_override("font_color", Color(1, 0.8, 0.3))
	hbox.add_child(_fight_button)

func _build_search_tab(tab_name: String, search_ph: String, container_out: Array) -> Control:
	var vbox := VBoxContainer.new()
	vbox.name = tab_name
	vbox.add_theme_constant_override("separation", 6)
	
	var search := LineEdit.new()
	search.placeholder_text = search_ph
	search.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(search)
	
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	
	container_out.append(list)
	return vbox

func _build_enemy_tab() -> Control:
	var result: Array = []
	var tab = _build_search_tab("Enemy", "Search enemies...", result)
	_enemy_search = tab.get_child(0)
	_enemy_container = result[0]
	_enemy_search.text_changed.connect(_on_enemy_search)
	return tab

func _build_card_tab() -> Control:
	var result: Array = []
	var tab = _build_search_tab("Cards", "Search cards...", result)
	_card_search = tab.get_child(0)
	_card_container = result[0]
	_card_search.text_changed.connect(_on_card_search)
	return tab

func _build_artifact_tab() -> Control:
	var result: Array = []
	var tab = _build_search_tab("Artifacts", "Search artifacts...", result)
	_artifact_search = tab.get_child(0)
	_artifact_container = result[0]
	_artifact_search.text_changed.connect(_on_artifact_search)
	return tab

func _build_consumable_tab() -> Control:
	var result: Array = []
	var tab = _build_search_tab("Consumables", "Search consumables...", result)
	_consumable_search = tab.get_child(0)
	_consumable_container = result[0]
	_consumable_search.text_changed.connect(_on_consumable_search)
	return tab

#region Data collection
func _collect_all_data():
	_all_enemies = Global.get_all_enemy_data()
	
	_all_cards = Global.get_all_cards()
	_all_cards.sort_custom(func(a, b): return I18N.get_card_name(a) < I18N.get_card_name(b))
	
	var raw_arts = Global.get_all_artifacts()
	_all_artifacts = []
	for a in raw_arts:
		if a != null: _all_artifacts.append(a)
	_all_artifacts.sort_custom(func(a, b): return I18N.get_artifact_name(a) < I18N.get_artifact_name(b))
	
	_all_consumables = []
	if "get_all_consumables" in Global.get_method_list().map(func(m): return m.name):
		_all_consumables = Global.get_all_consumables()
	else:
		for cid in Global._id_to_consumable_data:
			var cd = Global._id_to_consumable_data[cid]
			if cd != null: _all_consumables.append(cd)
	_all_consumables.sort_custom(func(a, b): return I18N.get_consumable_name(a) < I18N.get_consumable_name(b))
#endregion

#region Search handlers
func _on_enemy_search(t): _refresh_enemies(t)
func _on_card_search(t): _refresh_cards(t)
func _on_artifact_search(t): _refresh_artifacts(t)
func _on_consumable_search(t): _refresh_consumables(t)
#endregion

#region Render enemies (radio-style)
func _refresh_enemies(filter: String):
	if not _enemy_container: return
	_clear(_enemy_container)
	
	var lower = filter.to_lower()
	for ed in _all_enemies:
		var name = I18N.tr_data(ed.object_id, "enemy_name", ed.enemy_name)
		if filter != "" and lower not in name.to_lower() and lower not in ed.object_id.to_lower():
			continue
		
		var btn = Button.new()
		var type_str = ""
		match ed.enemy_type:
			0: type_str = " [" + I18N.tr_key("test.type_normal") + "]"
			1: type_str = " [" + I18N.tr_key("test.type_elite") + "]"
			2: type_str = " [" + I18N.tr_key("test.type_boss") + "]"
		btn.text = name + type_str + "  (HP: " + str(ed.enemy_health) + ")"
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size.y = 38
		btn.tooltip_text = "ID: %s | HP: %d" % [ed.object_id, ed.enemy_health]
		_style_item(btn)
		
		if selected_enemy_id == ed.object_id:
			_highlight_item(btn)
			btn.add_theme_color_override("font_color", Color(1, 0.85, 0.3))
		
		btn.pressed.connect(_on_enemy_picked.bind(ed.object_id))
		_enemy_container.add_child(btn)

func _on_enemy_picked(id: String):
	selected_enemy_id = id
	_refresh_enemies(_enemy_search.text)
	_update_display()
#endregion

#region Render cards (toggle)
func _refresh_cards(filter: String):
	if not _card_container: return
	_clear(_card_container)
	var lower = filter.to_lower()
	
	for cd in _all_cards:
		var cn: String = I18N.get_card_name(cd)
		if filter != "" and lower not in cn.to_lower() and lower not in cd.object_id.to_lower():
			continue

		var toggled = cd.object_id in selected_card_ids
		var cost_str = str(cd.card_energy_cost) if not cd.card_energy_cost_is_variable else "X"
		var btn = Button.new()
		btn.text = ("☑ " if toggled else "☐ ") + cn + "  [" + cost_str + " " + I18N.tr_key("test.energy") + "]"
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size.y = 32
		btn.modulate = Color(1, 1, 1) if toggled else Color(0.7, 0.7, 0.7)
		btn.tooltip_text = "ID: " + cd.object_id
		_style_item(btn)
		btn.pressed.connect(_on_card_toggled.bind(cd.object_id, btn))
		_card_container.add_child(btn)

func _on_card_toggled(id: String, btn: Button):
	if id in selected_card_ids:
		selected_card_ids.erase(id)
		btn.modulate = Color(0.7, 0.7, 0.7)
		btn.text = "☐ " + btn.text.substr(2)
	else:
		selected_card_ids.append(id)
		btn.modulate = Color(1, 1, 1)
		btn.text = "☑ " + btn.text.substr(2)
	_update_display()
#endregion

#region Render artifacts (toggle)
func _refresh_artifacts(filter: String):
	if not _artifact_container: return
	_clear(_artifact_container)
	var lower = filter.to_lower()
	
	for ad in _all_artifacts:
		var an: String = I18N.get_artifact_name(ad)
		if filter != "" and lower not in an.to_lower() and lower not in ad.object_id.to_lower():
			continue

		var toggled = ad.object_id in selected_artifact_ids
		var btn = Button.new()
		btn.text = ("☑ " if toggled else "☐ ") + an
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size.y = 32
		btn.modulate = Color(1, 1, 1) if toggled else Color(0.7, 0.7, 0.7)
		btn.tooltip_text = "ID: " + ad.object_id
		_style_item(btn)
		btn.pressed.connect(_on_artifact_toggled.bind(ad.object_id, btn))
		_artifact_container.add_child(btn)

func _on_artifact_toggled(id: String, btn: Button):
	if id in selected_artifact_ids:
		selected_artifact_ids.erase(id)
		btn.modulate = Color(0.7, 0.7, 0.7)
		btn.text = "☐ " + btn.text.substr(2)
	else:
		selected_artifact_ids.append(id)
		btn.modulate = Color(1, 1, 1)
		btn.text = "☑ " + btn.text.substr(2)
	_update_display()
#endregion

#region Render consumables (toggle)
func _refresh_consumables(filter: String):
	if not _consumable_container: return
	_clear(_consumable_container)
	var lower = filter.to_lower()
	
	for cd in _all_consumables:
		var cn: String = I18N.get_consumable_name(cd)
		if filter != "" and lower not in cn.to_lower() and lower not in cd.object_id.to_lower():
			continue

		var toggled = cd.object_id in selected_consumable_ids
		var btn = Button.new()
		btn.text = ("☑ " if toggled else "☐ ") + cn
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size.y = 32
		btn.modulate = Color(1, 1, 1) if toggled else Color(0.7, 0.7, 0.7)
		btn.tooltip_text = "ID: " + cd.object_id
		_style_item(btn)
		btn.pressed.connect(_on_consumable_toggled.bind(cd.object_id, btn))
		_consumable_container.add_child(btn)

func _on_consumable_toggled(id: String, btn: Button):
	if id in selected_consumable_ids:
		selected_consumable_ids.erase(id)
		btn.modulate = Color(0.7, 0.7, 0.7)
		btn.text = "☐ " + btn.text.substr(2)
	else:
		selected_consumable_ids.append(id)
		btn.modulate = Color(1, 1, 1)
		btn.text = "☑ " + btn.text.substr(2)
	_update_display()
#endregion

#region Helpers
func _clear(c: VBoxContainer):
	for ch in c.get_children():
		ch.queue_free()

func _style_item(btn: Button):
	btn.add_theme_font_size_override("font_size", 15)
	btn.add_theme_color_override("font_color", Color(0.96, 0.93, 0.82))
	btn.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.65))
	btn.add_theme_constant_override("outline_size", 1)

func _highlight_item(btn: Button):
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.25, 0.2, 0.1, 0.5)
	sb.border_color = Color(0.9, 0.7, 0.2, 0.6)
	sb.border_width_left = 3
	btn.add_theme_stylebox_override("normal", sb)

func _style_button(btn: Button):
	btn.add_theme_font_size_override("font_size", 20)
	btn.add_theme_color_override("font_color", Color(0.96, 0.93, 0.82))
	btn.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.65))
	btn.add_theme_constant_override("outline_size", 1)

func _update_display():
	var parts: Array[String] = []
	if selected_enemy_id != "":
		var ed = Global.get_enemy_data(selected_enemy_id)
		if ed: parts.append("Enemy: " + I18N.get_enemy_name(ed))
	if selected_card_ids.size() > 0: parts.append("Cards: " + str(selected_card_ids.size()))
	if selected_artifact_ids.size() > 0: parts.append("Artifacts: " + str(selected_artifact_ids.size()))
	if selected_consumable_ids.size() > 0: parts.append("Consumables: " + str(selected_consumable_ids.size()))
	
	if parts.is_empty():
		_selected_display.text = I18N.tr_key("test.select_hint")
	else:
		_selected_display.text = " | ".join(parts)
#endregion

func _on_fight():
	if selected_enemy_id == "":
		_selected_display.text = I18N.tr_key("test.no_enemy")
		return
	
	Global.start_test_combat(selected_enemy_id,
		Global.get_all_character_ids()[0],
		selected_card_ids,
		selected_artifact_ids,
		selected_consumable_ids)

func _on_back():
	var parent = get_parent()
	if parent and parent.has_method("show_main_menu"):
		parent.show_main_menu()
