## UI component for a selectable option. Used for run start options and dialogue options.
## Supports rich text.
extends PanelContainer
class_name DialogueOption

@onready var rich_text_label = $RichTextLabel

const NORMAL_BG: Color = Color(0.12, 0.125, 0.145, 0.97)
const NORMAL_BORDER: Color = Color(0.43, 0.38, 0.285, 1.0)
const HOVER_BG: Color = Color(0.18, 0.17, 0.15, 1.0)
const HOVER_BORDER: Color = Color(0.85, 0.68, 0.36, 1.0)
const DISABLED_BG: Color = Color(0.09, 0.09, 0.1, 0.82)
const DISABLED_BORDER: Color = Color(0.22, 0.22, 0.24, 1.0)

## The dialogue option this button represents. Run start option buttons will have this as empty.
var dialogue_option_object_id: String = ""

var action_data: Array[Dictionary] = []
var validators: Array[Dictionary] = []
var option_enabled: bool = false

signal dialogue_option_clicked(dialogue_option: DialogueOption)

func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	rich_text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rich_text_label.add_theme_font_size_override("normal_font_size", 16)
	gui_input.connect(_on_gui_input)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	_apply_style(false)

func init(_dialogue_option_object_id: String, option_bbcode: String, option_failed_validator_bbcode: String, _action_data: Array[Dictionary], _validators: Array[Dictionary]) -> void:
	dialogue_option_object_id = _dialogue_option_object_id
	action_data = _action_data
	validators = _validators
	option_enabled = validate_dialogue_option()
	if option_enabled:
		set_dialogue_bb_code(option_bbcode)
	else:
		set_dialogue_bb_code(option_failed_validator_bbcode)
	_apply_style(false)

func validate_dialogue_option() -> bool:
	# checks if option passes all validators
	return Global.validate(validators, null, null)

func set_dialogue_bb_code(bb_code: String) -> void:
	rich_text_label.parse_bbcode(bb_code)

func _apply_style(is_hovered: bool) -> void:
	var background_color: Color = NORMAL_BG
	var border_color: Color = NORMAL_BORDER
	if not option_enabled:
		background_color = DISABLED_BG
		border_color = DISABLED_BORDER
	elif is_hovered:
		background_color = HOVER_BG
		border_color = HOVER_BORDER
	add_theme_stylebox_override("panel", _make_panel_style(background_color, border_color))
	modulate.a = 1.0 if option_enabled else 0.72

func _make_panel_style(background_color: Color, border_color: Color) -> StyleBoxFlat:
	var style_box := StyleBoxFlat.new()
	style_box.bg_color = background_color
	style_box.border_color = border_color
	style_box.set_border_width_all(2)
	style_box.set_corner_radius_all(6)
	style_box.content_margin_left = 18.0
	style_box.content_margin_right = 18.0
	style_box.content_margin_top = 10.0
	style_box.content_margin_bottom = 10.0
	return style_box

func _on_mouse_entered() -> void:
	_apply_style(true)

func _on_mouse_exited() -> void:
	_apply_style(false)

func _on_gui_input(event: InputEvent):
	if option_enabled:
		if event.is_action_pressed("left_click"):
			dialogue_option_clicked.emit(self)
