extends BaseCustomUI
class_name StarChartUI
## Star Chart UI — vertical labels to the right of the character.
## Only houses with stars are displayed, from top to bottom.

const HOUSE_NAMES := ["黎明", "正午", "黄昏", "夜晚", "智慧", "命运"]
const HOUSE_COLORS := [
	Color(1.0, 0.85, 0.4),   # Dawn — gold
	Color(1.0, 0.45, 0.2),   # Noon — orange
	Color(0.7, 0.35, 0.85),  # Dusk — purple
	Color(0.25, 0.35, 0.95), # Night — blue
	Color(0.25, 0.9, 0.65),  # Wisdom — green
	Color(0.95, 0.25, 0.9),  # Fate — magenta
]

var _vbox: VBoxContainer
var _labels: Array[Label] = []

func init(_custom_ui_object_id: String, _parent_combatant: BaseCombatant) -> void:
	print("[StarChartUI] init called")
	super(_custom_ui_object_id, _parent_combatant)
	_setup_ui()
	if not Signals.star_placed.is_connected(_on_star_changed):
		Signals.star_placed.connect(_on_star_changed)
		Signals.star_consumed.connect(_on_star_changed)
		Signals.eclipse_triggered.connect(_on_eclipse)
	_refresh()

func _setup_ui() -> void:
	custom_minimum_size = Vector2(100, 30)
	size = Vector2(100, 30)
	position = Vector2(200, -80)

	_vbox = VBoxContainer.new()
	_vbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	_vbox.add_theme_constant_override("separation", 4)
	_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_vbox)

	for i in range(6):
		var lbl := Label.new()
		lbl.add_theme_font_size_override("font_size", 22)
		lbl.add_theme_color_override("font_color", Color.WHITE)
		lbl.visible = false
		lbl.modulate = Color(1, 1, 1, 0)
		_vbox.add_child(lbl)
		_labels.append(lbl)

func _on_star_changed(_house: int = -1, _count: int = 0) -> void:
	print("[StarChartUI] _on_star_changed house=%d" % _house)
	_refresh()

func _on_eclipse(_total: int) -> void:
	_refresh()
	modulate = Color(2, 2, 2)
	var tw := create_tween()
	tw.tween_property(self, "modulate", Color.WHITE, 0.5)

func _refresh() -> void:
	var chart := StarChartHelper.get_star_chart()
	print("[StarChartUI] _refresh chart=%s visible_labels=%d" % [chart, _labels.size()])
	for i in range(6):
		var count: int = int(chart[i])
		var lbl: Label = _labels[i]
		if count > 0:
			var stars := ""
			var display_count := mini(count, 6)
			for s in range(display_count):
				stars += "★"
			if count > 6:
				stars += "+%d" % (count - 6)
			lbl.text = "%s %s" % [HOUSE_NAMES[i], stars]
			lbl.add_theme_color_override("font_color", HOUSE_COLORS[i])
			if not lbl.visible:
				lbl.visible = true
				lbl.modulate = Color(1, 1, 1, 0)
				lbl.position.x = -30
				var tw := create_tween()
				tw.tween_property(lbl, "modulate", Color(1, 1, 1, 1), 0.2)
				tw.parallel().tween_property(lbl, "position:x", 0, 0.2)
		else:
			if lbl.visible:
				# Kill any existing tweens on this label to prevent conflicts
				var tw := create_tween()
				tw.tween_property(lbl, "modulate", Color(1, 1, 1, 0), 0.15)
				tw.tween_callback(func(): lbl.visible = false)

# --- Selection mode ---

var _in_selection_mode: bool = false
var _selection_callback: Callable

func enter_selection_mode(callback: Callable) -> void:
	_in_selection_mode = true
	_selection_callback = callback
	for i in range(6):
		if _labels[i].visible:
			_labels[i].add_theme_color_override("font_color", Color.WHITE)
			_labels[i].mouse_filter = Control.MOUSE_FILTER_STOP
			# Store house index as metadata for click detection
			_labels[i].set_meta("house_index", i)

func exit_selection_mode() -> void:
	_in_selection_mode = false
	_selection_callback = Callable()
	var chart := StarChartHelper.get_star_chart()
	for i in range(6):
		if int(chart[i]) > 0:
			_labels[i].add_theme_color_override("font_color", HOUSE_COLORS[i])
			_labels[i].mouse_filter = Control.MOUSE_FILTER_PASS
		if _labels[i].has_meta("house_index"):
			_labels[i].remove_meta("house_index")

func _gui_input(event: InputEvent) -> void:
	if not _in_selection_mode:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		for i in range(6):
			if _labels[i].visible and _labels[i].get_global_rect().has_point(event.global_position):
				var cb := _selection_callback
				exit_selection_mode()
				cb.call(i)
				return
