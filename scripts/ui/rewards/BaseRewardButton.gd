extends Button
class_name BaseRewardButton

const BUTTON_MIN_SIZE := Vector2(472, 64)
const NORMAL_BG := Color(0.122, 0.133, 0.153, 0.98)
const NORMAL_BORDER := Color(0.431, 0.392, 0.282, 1.0)
const HOVER_BG := Color(0.176, 0.192, 0.218, 1.0)
const HOVER_BORDER := Color(0.765, 0.663, 0.376, 1.0)
const PRESSED_BG := Color(0.086, 0.096, 0.114, 1.0)
const PRESSED_BORDER := Color(0.502, 0.678, 0.627, 1.0)
const FOCUS_BORDER := Color(0.88, 0.827, 0.569, 1.0)

var action_on_click: BaseAction = null
var reward_group: int = 0

func _ready():
	_apply_reward_button_style()
	button_up.connect(_on_button_up)

func init(_action_on_click: BaseAction, _reward_group: int) -> void:
	action_on_click = _action_on_click
	reward_group = _reward_group

func refresh_localized_text() -> void:
	pass

func _on_button_up():
	if action_on_click != null:
		ActionHandler.add_action(action_on_click)
	queue_free()

func _apply_reward_button_style() -> void:
	custom_minimum_size = BUTTON_MIN_SIZE
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	focus_mode = Control.FOCUS_ALL
	clip_text = true
	text_overrun_behavior = TextServer.OVERRUN_TRIM_WORD_ELLIPSIS
	expand_icon = true
	alignment = HORIZONTAL_ALIGNMENT_LEFT
	icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER

	add_theme_font_size_override("font_size", 18)
	add_theme_constant_override("h_separation", 16)
	add_theme_constant_override("icon_max_width", 36)
	add_theme_color_override("font_color", Color(0.945, 0.914, 0.788, 1.0))
	add_theme_color_override("font_hover_color", Color(1.0, 0.973, 0.831, 1.0))
	add_theme_color_override("font_pressed_color", Color(0.835, 0.82, 0.745, 1.0))
	add_theme_color_override("font_focus_color", Color(1.0, 0.973, 0.831, 1.0))
	add_theme_color_override("font_outline_color", Color(0.02, 0.018, 0.016, 0.95))
	add_theme_constant_override("outline_size", 1)
	add_theme_stylebox_override("normal", _make_button_style(NORMAL_BG, NORMAL_BORDER))
	add_theme_stylebox_override("hover", _make_button_style(HOVER_BG, HOVER_BORDER))
	add_theme_stylebox_override("pressed", _make_button_style(PRESSED_BG, PRESSED_BORDER))
	add_theme_stylebox_override("focus", _make_button_style(Color(0, 0, 0, 0), FOCUS_BORDER))

func _make_button_style(background_color: Color, border_color: Color) -> StyleBoxFlat:
	var style_box := StyleBoxFlat.new()
	style_box.bg_color = background_color
	style_box.border_color = border_color
	style_box.set_border_width_all(2)
	style_box.set_corner_radius_all(7)
	style_box.content_margin_left = 18.0
	style_box.content_margin_right = 18.0
	style_box.content_margin_top = 10.0
	style_box.content_margin_bottom = 10.0
	return style_box
