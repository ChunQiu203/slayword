extends TextureButton
class_name MapLocation

## 地图格子上显示的节点边长；与 `Map.gd` 里 `MAP_NODE_SIZE` 对齐。
const MAP_NODE_DISPLAY_SIZE: Vector2 = Vector2(72, 72)
const DESIGN_NODE_PX: float = 40.0

var location_data: LocationData = null
var is_reachable: bool = false
var is_current: bool = false

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var map_label: Label = $MapLabel

signal map_location_button_up(map_location: MapLocation)

func _ready():
	button_up.connect(_on_button_up)
	mouse_entered.connect(_on_draw_state_changed)
	mouse_exited.connect(_on_draw_state_changed)
	focus_entered.connect(_on_draw_state_changed)
	focus_exited.connect(_on_draw_state_changed)
	
	custom_minimum_size = MAP_NODE_DISPLAY_SIZE
	size = MAP_NODE_DISPLAY_SIZE
	map_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_label_font_size()

func _apply_label_font_size() -> void:
	var ps: float = size.x / DESIGN_NODE_PX
	map_label.add_theme_font_size_override("font_size", int(round(26.0 * ps)))

func init(_location_data: LocationData, _is_reachable: bool = false, _is_current: bool = false):
	location_data = _location_data
	is_reachable = _is_reachable
	is_current = _is_current
	
	var uses_question_mark: bool = _uses_question_mark()
	map_label.visible = uses_question_mark
	map_label.text = "?" if uses_question_mark else ""
	map_label.modulate = _get_icon_color()
	tooltip_text = _get_tooltip_text()
	queue_redraw()

func flash_location() -> void:
	animation_player.play("flash_map_location")

func _on_button_up():
	map_location_button_up.emit(self)

func _on_draw_state_changed() -> void:
	queue_redraw()

func _pixel_scale() -> float:
	return clampf(size.x / DESIGN_NODE_PX, 0.25, 4.0)

func _draw() -> void:
	if location_data == null:
		return
	
	var ps: float = _pixel_scale()
	var center: Vector2 = size * 0.5
	var icon_color: Color = _get_icon_color()
	
	if is_reachable or is_current or is_hovered() or has_focus():
		draw_circle(center, 18.0 * ps, Color(0.15, 0.18, 0.18, 0.08))
		draw_arc(center, 17.0 * ps, 0.0, TAU, int(round(48.0 * ps)), icon_color, 1.2 * ps, true)
	
	if _uses_question_mark():
		return
	
	match location_data.location_type:
		LocationData.LOCATION_TYPES.COMBAT:
			_draw_combat_icon(center, icon_color, 1.0, ps)
		LocationData.LOCATION_TYPES.MINIBOSS:
			_draw_combat_icon(center, icon_color, 1.12, ps)
			_draw_miniboss_mark(center, icon_color, ps)
		LocationData.LOCATION_TYPES.BOSS:
			_draw_boss_icon(center, icon_color, ps)
		LocationData.LOCATION_TYPES.TREASURE:
			_draw_treasure_icon(center, icon_color, ps)
		LocationData.LOCATION_TYPES.SHOP:
			_draw_shop_icon(center, icon_color, ps)
		LocationData.LOCATION_TYPES.REST_SITE:
			_draw_rest_icon(center, icon_color, ps)
		_:
			_draw_combat_icon(center, icon_color, 1.0, ps)

func _uses_question_mark() -> bool:
	if location_data == null:
		return false
	var is_hidden: bool = location_data.location_obfuscated and not location_data.location_visited
	return is_hidden or location_data.location_type == LocationData.LOCATION_TYPES.EVENT

func _get_icon_color() -> Color:
	if is_current:
		return Color(0.11, 0.18, 0.18, 0.95)
	if is_reachable:
		return Color(0.12, 0.22, 0.24, 0.95)
	if location_data != null and location_data.location_visited:
		return Color(0.20, 0.27, 0.26, 0.74)
	return Color(0.28, 0.31, 0.31, 0.58)

func _get_tooltip_text() -> String:
	if location_data.location_obfuscated and not location_data.location_visited:
		return I18N.tr_key("map.unknown")
	return I18N.tr_enum("map", LocationData.LOCATION_TYPES.keys()[location_data.location_type])

func _draw_combat_icon(center: Vector2, color: Color, shape_scale: float, ps: float) -> void:
	var radius: float = 7.5 * shape_scale * ps
	var face_center: Vector2 = center + Vector2(0.0, 3.0) * ps
	var lw: float = 1.5 * ps
	draw_arc(face_center, radius, 0.0, TAU, int(round(36.0 * ps)), color, lw, true)
	draw_line(face_center + Vector2(-5.0, -4.0) * shape_scale * ps, face_center + Vector2(-12.0, -10.0) * shape_scale * ps, color, lw, true)
	draw_line(face_center + Vector2(-12.0, -10.0) * shape_scale * ps, face_center + Vector2(-10.0, -1.0) * shape_scale * ps, color, lw, true)
	draw_line(face_center + Vector2(5.0, -4.0) * shape_scale * ps, face_center + Vector2(12.0, -10.0) * shape_scale * ps, color, lw, true)
	draw_line(face_center + Vector2(12.0, -10.0) * shape_scale * ps, face_center + Vector2(10.0, -1.0) * shape_scale * ps, color, lw, true)
	draw_circle(face_center + Vector2(-3.0, -1.0) * shape_scale * ps, 1.2 * shape_scale * ps, color)
	draw_circle(face_center + Vector2(3.0, -1.0) * shape_scale * ps, 1.2 * shape_scale * ps, color)
	draw_line(face_center + Vector2(-3.0, 4.0) * shape_scale * ps, face_center + Vector2(3.0, 4.0) * shape_scale * ps, color, 1.3 * ps, true)

func _draw_miniboss_mark(center: Vector2, color: Color, ps: float) -> void:
	var lw: float = 1.4 * ps
	draw_line(center + Vector2(-5.0, -13.0) * ps, center + Vector2(0.0, -17.0) * ps, color, lw, true)
	draw_line(center + Vector2(0.0, -17.0) * ps, center + Vector2(5.0, -13.0) * ps, color, lw, true)

func _draw_boss_icon(center: Vector2, color: Color, ps: float) -> void:
	var lw: float = 1.8 * ps
	var face_center: Vector2 = center + Vector2(0.0, 3.0) * ps
	draw_arc(face_center, 10.5 * ps, 0.0, TAU, int(round(40.0 * ps)), color, lw, true)
	draw_line(face_center + Vector2(-7.0, -5.0) * ps, face_center + Vector2(-16.0, -13.0) * ps, color, lw, true)
	draw_line(face_center + Vector2(-16.0, -13.0) * ps, face_center + Vector2(-14.0, 0.0) * ps, color, lw, true)
	draw_line(face_center + Vector2(7.0, -5.0) * ps, face_center + Vector2(16.0, -13.0) * ps, color, lw, true)
	draw_line(face_center + Vector2(16.0, -13.0) * ps, face_center + Vector2(14.0, 0.0) * ps, color, lw, true)
	draw_line(face_center + Vector2(-7.0, -11.0) * ps, face_center + Vector2(-3.0, -16.0) * ps, color, 1.6 * ps, true)
	draw_line(face_center + Vector2(-3.0, -16.0) * ps, face_center + Vector2(0.0, -11.0) * ps, color, 1.6 * ps, true)
	draw_line(face_center + Vector2(0.0, -11.0) * ps, face_center + Vector2(3.0, -16.0) * ps, color, 1.6 * ps, true)
	draw_line(face_center + Vector2(3.0, -16.0) * ps, face_center + Vector2(7.0, -11.0) * ps, color, 1.6 * ps, true)
	draw_circle(face_center + Vector2(-4.0, -1.0) * ps, 1.4 * ps, color)
	draw_circle(face_center + Vector2(4.0, -1.0) * ps, 1.4 * ps, color)
	draw_line(face_center + Vector2(-4.0, 5.0) * ps, face_center + Vector2(4.0, 5.0) * ps, color, 1.4 * ps, true)

func _draw_treasure_icon(center: Vector2, color: Color, ps: float) -> void:
	var lw: float = 1.6 * ps
	var body: Rect2 = Rect2(center + Vector2(-11.0, -2.0) * ps, Vector2(22.0, 13.0) * ps)
	draw_rect(body, color, false, lw)
	draw_line(center + Vector2(-9.0, -2.0) * ps, center + Vector2(-6.0, -8.0) * ps, color, lw, true)
	draw_line(center + Vector2(-6.0, -8.0) * ps, center + Vector2(6.0, -8.0) * ps, color, lw, true)
	draw_line(center + Vector2(6.0, -8.0) * ps, center + Vector2(9.0, -2.0) * ps, color, lw, true)
	draw_line(center + Vector2(0.0, -8.0) * ps, center + Vector2(0.0, 11.0) * ps, color, 1.2 * ps, true)
	draw_rect(Rect2(center + Vector2(-2.0, 3.0) * ps, Vector2(4.0, 4.0) * ps), color, false, 1.2 * ps)

func _draw_shop_icon(center: Vector2, color: Color, ps: float) -> void:
	var lw: float = 1.5 * ps
	draw_line(center + Vector2(-6.0, -10.0) * ps, center + Vector2(6.0, -10.0) * ps, color, lw, true)
	draw_line(center + Vector2(-6.0, -10.0) * ps, center + Vector2(-10.0, 1.0) * ps, color, lw, true)
	draw_line(center + Vector2(6.0, -10.0) * ps, center + Vector2(10.0, 1.0) * ps, color, lw, true)
	draw_arc(center + Vector2(0.0, 3.0) * ps, 10.0 * ps, 0.0, TAU, int(round(36.0 * ps)), color, 1.6 * ps, true)
	draw_circle(center + Vector2(4.0, 5.0) * ps, 3.0 * ps, Color(color.r, color.g, color.b, color.a * 0.35))
	draw_arc(center + Vector2(4.0, 5.0) * ps, 3.0 * ps, 0.0, TAU, int(round(20.0 * ps)), color, 1.0 * ps, true)

func _draw_rest_icon(center: Vector2, color: Color, ps: float) -> void:
	draw_line(center + Vector2(-10.0, 11.0) * ps, center + Vector2(9.0, 6.0) * ps, color, 1.5 * ps, true)
	draw_line(center + Vector2(-9.0, 6.0) * ps, center + Vector2(10.0, 11.0) * ps, color, 1.5 * ps, true)
	draw_line(center + Vector2(0.0, -11.0) * ps, center + Vector2(-6.0, 2.0) * ps, color, 1.6 * ps, true)
	draw_line(center + Vector2(-6.0, 2.0) * ps, center + Vector2(0.0, 8.0) * ps, color, 1.6 * ps, true)
	draw_line(center + Vector2(0.0, 8.0) * ps, center + Vector2(6.0, 2.0) * ps, color, 1.6 * ps, true)
	draw_line(center + Vector2(6.0, 2.0) * ps, center + Vector2(0.0, -11.0) * ps, color, 1.6 * ps, true)
	draw_line(center + Vector2(1.0, -4.0) * ps, center + Vector2(-2.0, 4.0) * ps, color, 1.2 * ps, true)
	draw_line(center + Vector2(-2.0, 4.0) * ps, center + Vector2(2.0, 4.0) * ps, color, 1.2 * ps, true)
