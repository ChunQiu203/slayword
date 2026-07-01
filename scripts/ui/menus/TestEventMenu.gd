# Test event menu - pick an event + loadout, then trigger it.
extends Control

var _event_container: VBoxContainer
var _card_container: VBoxContainer
var _artifact_container: VBoxContainer
var _event_search: LineEdit
var _card_search: LineEdit
var _artifact_search: LineEdit
var _selected_display: Label
var _tab_container: TabContainer
var _back_button: Button
var _start_button: Button

var selected_event_id: String = ""
var selected_card_ids: Array[String] = []
var selected_artifact_ids: Array[String] = []

var _all_events: Array = []
var _all_cards: Array = []
var _all_artifacts: Array = []

var _event_list_events: Array[String] = [
	"event_pick_something",
	"event_ancient_ruins",
	"event_word_challenge",
	"event_cursed_chest",
	"event_traveler",
	"event_altar",
	"event_lucky",
]

func _ready():
	_build_ui()
	_collect_all_data()
	_refresh_events("")
	_refresh_cards("")
	_refresh_artifacts("")
	_update_display()
	if _tab_container:
		_tab_container.current_tab = 0
	I18N.locale_changed.connect(_on_locale_changed)

func _on_locale_changed(_locale: String):
	_refresh_all_labels()
	_collect_all_data()
	_refresh_events("")
	_refresh_cards("")
	_refresh_artifacts("")
	_update_display()

func _refresh_all_labels():
	if _tab_container:
		_tab_container.set_tab_title(0, I18N.tr_key("test_event.event"))
		_tab_container.set_tab_title(1, I18N.tr_key("test.cards"))
		_tab_container.set_tab_title(2, I18N.tr_key("test.artifacts"))
	if _back_button:
		_back_button.text = I18N.tr_key("menu.back")
	if _start_button:
		_start_button.text = I18N.tr_key("test_event.start")

func populate_test_menu():
	_collect_all_data()
	_refresh_events("")
	_refresh_cards("")
	_refresh_artifacts("")
	_update_display()
	if _tab_container:
		_tab_container.current_tab = 0

func _build_ui():
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

	var title := Label.new()
	title.text = I18N.tr_key("test_event.title")
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	vbox.add_child(title)

	_selected_display = Label.new()
	_selected_display.text = I18N.tr_key("test.select_hint")
	_selected_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_selected_display.add_theme_font_size_override("font_size", 16)
	_selected_display.add_theme_color_override("font_color", Color(0.9, 0.85, 0.7))
	vbox.add_child(_selected_display)

	_tab_container = TabContainer.new()
	_tab_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_tab_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_tab_container.add_theme_font_size_override("font_size", 16)
	vbox.add_child(_tab_container)

	var event_tab = _build_event_tab()
	_tab_container.add_child(event_tab)
	var card_tab = _build_card_tab()
	_tab_container.add_child(card_tab)
	var art_tab = _build_artifact_tab()
	_tab_container.add_child(art_tab)

	_tab_container.set_tab_title(0, I18N.tr_key("test_event.event"))
	_tab_container.set_tab_title(1, I18N.tr_key("test.cards"))
	_tab_container.set_tab_title(2, I18N.tr_key("test.artifacts"))

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

	_start_button = Button.new()
	_start_button.text = I18N.tr_key("test_event.start")
	_start_button.custom_minimum_size = Vector2(280, 56)
	_start_button.pressed.connect(_on_start)
	_style_button(_start_button)
	_start_button.add_theme_color_override("font_color", Color(1, 0.8, 0.3))
	hbox.add_child(_start_button)

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

func _build_event_tab() -> Control:
	var result: Array = []
	var tab = _build_search_tab("Event", "Search events...", result)
	_event_search = tab.get_child(0)
	_event_container = result[0]
	_event_search.text_changed.connect(_on_event_search)
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

#region Data collection
func _collect_all_data():
	_all_events = []
	for eid in _event_list_events:
		var ed = Global.get_event_data(eid)
		if ed != null:
			_all_events.append(ed)

	_all_cards = Global.get_all_cards()
	_all_cards.sort_custom(func(a, b): return I18N.get_card_name(a) < I18N.get_card_name(b))

	var raw_arts = Global.get_all_artifacts()
	_all_artifacts = []
	for a in raw_arts:
		if a != null: _all_artifacts.append(a)
	_all_artifacts.sort_custom(func(a, b): return I18N.get_artifact_name(a) < I18N.get_artifact_name(b))
#endregion

#region Search handlers
func _on_event_search(t): _refresh_events(t)
func _on_card_search(t): _refresh_cards(t)
func _on_artifact_search(t): _refresh_artifacts(t)
#endregion

#region Render events (radio-style)
func _refresh_events(filter: String):
	if not _event_container: return
	_clear(_event_container)
	var lower = filter.to_lower()

	for ed in _all_events:
		var en = I18N.tr_data(ed.object_id, "event_name", ed.object_id)
		if filter != "" and lower not in en.to_lower() and lower not in ed.object_id.to_lower():
			continue

		var btn = Button.new()
		var has_dialogue = ed.event_dialogue_object_id != ""
		var type_str = " [Dialogue]" if has_dialogue else " [Combat]"
		btn.text = en + type_str + "  (" + ed.object_id + ")"
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size.y = 38
		btn.tooltip_text = "ID: %s | Dialogue: %s" % [ed.object_id, ed.event_dialogue_object_id]
		_style_item(btn)

		if selected_event_id == ed.object_id:
			_highlight_item(btn)
			btn.add_theme_color_override("font_color", Color(1, 0.85, 0.3))

		btn.pressed.connect(_on_event_picked.bind(ed.object_id))
		_event_container.add_child(btn)

func _on_event_picked(id: String):
	selected_event_id = id
	_refresh_events(_event_search.text)
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
	if selected_event_id != "":
		var ed = Global.get_event_data(selected_event_id)
		if ed:
			var en = I18N.tr_data(ed.object_id, "event_name", ed.object_id)
			parts.append("Event: " + en)
	if selected_card_ids.size() > 0: parts.append("Cards: " + str(selected_card_ids.size()))
	if selected_artifact_ids.size() > 0: parts.append("Artifacts: " + str(selected_artifact_ids.size()))

	if parts.is_empty():
		_selected_display.text = I18N.tr_key("test.select_hint")
	else:
		_selected_display.text = " | ".join(parts)
#endregion

func _on_start():
	if selected_event_id == "":
		_selected_display.text = I18N.tr_key("test_event.no_event")
		return

	Global.start_test_event(selected_event_id,
		selected_card_ids,
		selected_artifact_ids)

func _on_back():
	var parent = get_parent()
	if parent and parent.has_method("show_main_menu"):
		parent.show_main_menu()
