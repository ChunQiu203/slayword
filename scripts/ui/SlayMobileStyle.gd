extends RefCounted
class_name SlayMobileStyle

const TOUCH_H := 58.0
const GAP := 12
const BG_PANEL := Color(0.055, 0.065, 0.070, 0.92)
const BG_PANEL_LIGHT := Color(0.115, 0.135, 0.135, 0.94)
const BORDER_GOLD := Color(0.78, 0.65, 0.34, 0.95)
const BORDER_MUTED := Color(0.42, 0.36, 0.24, 0.95)
const TEXT_MAIN := Color(0.97, 0.93, 0.80, 1.0)
const TEXT_MUTED := Color(0.78, 0.80, 0.76, 0.92)
const TEXT_WARN := Color(1.0, 0.55, 0.50, 1.0)
const RED := Color(0.58, 0.12, 0.12, 0.96)
const RED_HOVER := Color(0.72, 0.18, 0.15, 0.98)
const GREEN := Color(0.25, 0.42, 0.39, 0.96)
const GREEN_HOVER := Color(0.33, 0.54, 0.50, 0.98)


static func panel_style(fill: Color = BG_PANEL, border: Color = BORDER_MUTED, radius: int = 8) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = border
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 14
	sb.content_margin_bottom = 14
	sb.shadow_color = Color(0, 0, 0, 0.44)
	sb.shadow_size = 10
	sb.shadow_offset = Vector2(0, 5)
	return sb


static func button_style(fill: Color, border: Color, radius: int = 8) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = border
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	return sb


static func style_button(btn: BaseButton, kind: String = "dark", font_size: int = 22) -> void:
	var normal := BG_PANEL_LIGHT
	var hover := Color(0.17, 0.19, 0.19, 0.98)
	var border := BORDER_MUTED
	if kind == "red":
		normal = RED
		hover = RED_HOVER
		border = Color(0.95, 0.60, 0.35, 0.96)
	elif kind == "green":
		normal = GREEN
		hover = GREEN_HOVER
		border = Color(0.62, 0.82, 0.74, 0.88)
	elif kind == "gold":
		normal = Color(0.24, 0.19, 0.08, 0.96)
		hover = Color(0.34, 0.26, 0.10, 0.98)
		border = BORDER_GOLD
	btn.custom_minimum_size.y = maxf(btn.custom_minimum_size.y, TOUCH_H)
	btn.add_theme_font_size_override("font_size", font_size)
	btn.add_theme_color_override("font_color", TEXT_MAIN)
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.96, 0.82, 1.0))
	btn.add_theme_color_override("font_pressed_color", Color(0.86, 0.78, 0.58, 1.0))
	btn.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.75))
	btn.add_theme_constant_override("outline_size", 1)
	btn.add_theme_stylebox_override("normal", button_style(normal, border))
	btn.add_theme_stylebox_override("hover", button_style(hover, border))
	btn.add_theme_stylebox_override("pressed", button_style(normal.darkened(0.18), border))
	btn.add_theme_stylebox_override("focus", button_style(hover, BORDER_GOLD))
	btn.add_theme_stylebox_override("disabled", button_style(Color(0.10, 0.10, 0.10, 0.72), Color(0.24, 0.22, 0.18, 0.72)))


static func style_label(label: Label, font_size: int, color: Color = TEXT_MAIN, align: int = HORIZONTAL_ALIGNMENT_LEFT) -> void:
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.78))
	label.add_theme_constant_override("outline_size", 1)
	label.horizontal_alignment = align
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


static func style_line_edit(line_edit: LineEdit, font_size: int = 20) -> void:
	line_edit.custom_minimum_size.y = maxf(line_edit.custom_minimum_size.y, TOUCH_H)
	line_edit.add_theme_font_size_override("font_size", font_size)
	line_edit.add_theme_color_override("font_color", TEXT_MAIN)
	line_edit.add_theme_color_override("font_placeholder_color", TEXT_MUTED)
	line_edit.add_theme_color_override("caret_color", TEXT_MAIN)
	line_edit.add_theme_stylebox_override("normal", button_style(BG_PANEL_LIGHT, BORDER_MUTED, 6))
	line_edit.add_theme_stylebox_override("focus", button_style(Color(0.15, 0.17, 0.17, 0.98), BORDER_GOLD, 6))
