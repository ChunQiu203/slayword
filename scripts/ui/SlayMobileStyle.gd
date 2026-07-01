extends RefCounted
class_name SlayMobileStyle

# ── Layout ──────────────────────────────────
const TOUCH_H := 58.0
const GAP := 12

# ── Base palette ────────────────────────────
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

# ── Scene accent colours ────────────────────
const ACCENT_COMBAT  := Color(0.76, 0.28, 0.22, 0.96)   # rust-red
const ACCENT_REST    := Color(0.28, 0.60, 0.52, 0.96)   # teal
const ACCENT_SHOP    := Color(0.78, 0.65, 0.34, 0.95)   # gold (same as BORDER_GOLD)
const ACCENT_REWARD  := Color(0.55, 0.42, 0.72, 0.96)   # muted-purple

# ── Font paths ──────────────────────────────
const FONT_DIR := "res://themes/fonts/"
const FONT_TITLE_PATH := FONT_DIR + "Cinzel-Bold.ttf"
const FONT_TITLE_REGULAR_PATH := FONT_DIR + "Cinzel-Regular.ttf"
const FONT_BODY_PATH := FONT_DIR + "NotoSansSC-Regular.ttf"

# ── Font size scale ─────────────────────────
const FS_XS  := 12
const FS_SM  := 16
const FS_MD  := 20
const FS_LG  := 24
const FS_XL  := 32
const FS_XXL := 48

# ── Cached font references ──────────────────
static var _title_font: FontFile = null
static var _body_font: FontFile = null

# ── Viewport reference for scaling ──────────
const DESIGN_HEIGHT := 720.0
static var _viewport_size: Vector2i = Vector2i(1280, 720)


## Called by Root on startup and every window resize.
static func set_viewport_ref(size: Vector2i) -> void:
	_viewport_size = size


## Returns current viewport size (width, height).
static func get_viewport_size() -> Vector2i:
	return _viewport_size


## Scales a base font size proportionally to the current viewport height.
## All font sizes were designed at 720p.  At larger/smaller resolutions
## they scale linearly while being clamped to a readable minimum.
static func get_scaled_font_size(base_size: int) -> int:
	var h: float = float(_viewport_size.y)
	if h <= 0.0:
		return base_size
	var scale: float = h / DESIGN_HEIGHT
	var scaled: int = int(round(base_size * scale))
	return maxi(scaled, 10)  # never smaller than 10px


# ── Font loading ────────────────────────────────

## Try to load bundled .ttf font files.  Returns true if both fonts
## were loaded successfully, false otherwise (falls back to system font).
static func load_fonts() -> bool:
	if _title_font != null and _body_font != null:
		return true  # already loaded

	if ResourceLoader.exists(FONT_TITLE_PATH):
		_title_font = load(FONT_TITLE_PATH) as FontFile
	if ResourceLoader.exists(FONT_TITLE_REGULAR_PATH):
		pass  # optional – kept for future use (small-caps, etc.)
	if ResourceLoader.exists(FONT_BODY_PATH):
		_body_font = load(FONT_BODY_PATH) as FontFile

	return _title_font != null and _body_font != null


## Returns the title font if bundled, otherwise a SystemFont fallback.
static func get_title_font() -> Font:
	if _title_font != null:
		return _title_font
	# Fallback: system serif for editor / dev builds
	var sf := SystemFont.new()
	sf.font_names = PackedStringArray(["Georgia", "Times New Roman", "Droid Serif", "serif"])
	sf.font_italic = false
	return sf


## Returns the body font if bundled, otherwise a SystemFont fallback
## that covers Latin + CJK.
static func get_body_font() -> Font:
	if _body_font != null:
		return _body_font
	var sf := SystemFont.new()
	sf.font_names = PackedStringArray(["Segoe UI", "Microsoft YaHei", "Roboto", "Droid Sans Fallback", "Noto Sans CJK SC", "Noto Sans SC", "sans-serif"])
	sf.font_italic = false
	return sf


## Build a base Theme resource that carries font & colour defaults.
## Apply it to the root Control so every child inherits sensible defaults.
static func create_base_theme() -> Theme:
	var theme := Theme.new()

	var title_font := get_title_font()
	var body_font := get_body_font()

	# Button defaults
	theme.set_font("font", "Button", body_font)
	theme.set_font_size("font_size", "Button", FS_MD)

	# Label defaults
	theme.set_font("font", "Label", body_font)
	theme.set_font_size("font_size", "Label", FS_MD)

	# RichTextLabel defaults
	theme.set_font("normal_font", "RichTextLabel", body_font)
	theme.set_font_size("normal_font_size", "RichTextLabel", FS_MD)

	# LineEdit defaults
	theme.set_font("font", "LineEdit", body_font)
	theme.set_font_size("font_size", "LineEdit", FS_MD)

	# Title (large headings) — uses title font
	theme.set_font_size("font_size", "Label", FS_XL)

	return theme


# ── StyleBox helpers ────────────────────────────

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
	btn.add_theme_font_override("font", get_body_font())
	btn.add_theme_font_size_override("font_size", get_scaled_font_size(font_size))
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
	label.add_theme_font_override("font", get_body_font())
	label.add_theme_font_size_override("font_size", get_scaled_font_size(font_size))
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.78))
	label.add_theme_constant_override("outline_size", 1)
	label.horizontal_alignment = align
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


static func style_line_edit(line_edit: LineEdit, font_size: int = 20) -> void:
	line_edit.custom_minimum_size.y = maxf(line_edit.custom_minimum_size.y, TOUCH_H)
	line_edit.add_theme_font_override("font", get_body_font())
	line_edit.add_theme_font_size_override("font_size", get_scaled_font_size(font_size))
	line_edit.add_theme_color_override("font_color", TEXT_MAIN)
	line_edit.add_theme_color_override("font_placeholder_color", TEXT_MUTED)
	line_edit.add_theme_color_override("caret_color", TEXT_MAIN)
	line_edit.add_theme_stylebox_override("normal", button_style(BG_PANEL_LIGHT, BORDER_MUTED, 6))
	line_edit.add_theme_stylebox_override("focus", button_style(Color(0.15, 0.17, 0.17, 0.98), BORDER_GOLD, 6))


# ── Micro-animations ────────────────────────────

## Add a subtle scale-bounce to `btn` on hover (0.15 s).
## Safe to call repeatedly — existing tweens are killed first.
static func tween_button_hover(btn: Control) -> void:
	var tw := btn.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tw.tween_property(btn, "scale", Vector2(1.04, 1.04), 0.15)


## Add a subtle press-down scale to `btn` (0.08 s).
static func tween_button_press(btn: Control) -> void:
	var tw := btn.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(btn, "scale", Vector2(0.96, 0.96), 0.08)


## Restore the button back to identity scale (0.15 s).
static func tween_button_restore(btn: Control) -> void:
	var tw := btn.create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	tw.tween_property(btn, "scale", Vector2.ONE, 0.15)


## Fade-in + slide-up entrance for overlays / panels.
## `ctrl` — the Control to animate.  `from_y_offset` — slide distance in px (default 40).
static func tween_panel_enter(ctrl: Control, from_y_offset: float = 40.0) -> void:
	ctrl.modulate = Color.TRANSPARENT
	ctrl.position.y += from_y_offset
	var tw := ctrl.create_tween().set_parallel(true).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	tw.tween_property(ctrl, "modulate", Color.WHITE, 0.35)
	tw.tween_property(ctrl, "position:y", ctrl.position.y - from_y_offset, 0.35)
