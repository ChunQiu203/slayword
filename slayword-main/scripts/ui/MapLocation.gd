extends TextureButton
class_name MapLocation

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
	
	custom_minimum_size = Vector2(40, 40)
	size = Vector2(40, 40)
	map_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_label.add_theme_font_size_override("font_size", 26)

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

func _draw() -> void:
	if location_data == null:
		return
	
	var center: Vector2 = size * 0.5
	var icon_color: Color = _get_icon_color()
	
	if is_reachable or is_current or is_hovered() or has_focus():
		draw_circle(center, 18.0, Color(0.15, 0.18, 0.18, 0.08))
		draw_arc(center, 17.0, 0.0, TAU, 48, icon_color, 1.2, true)
	
	if _uses_question_mark():
		return
	
	match location_data.location_type:
		LocationData.LOCATION_TYPES.COMBAT:
			_draw_combat_icon(center, icon_color, 1.0)
		LocationData.LOCATION_TYPES.MINIBOSS:
			_draw_combat_icon(center, icon_color, 1.12)
			_draw_miniboss_mark(center, icon_color)
		LocationData.LOCATION_TYPES.BOSS:
			_draw_boss_icon(center, icon_color)
		LocationData.LOCATION_TYPES.TREASURE:
			_draw_treasure_icon(center, icon_color)
		LocationData.LOCATION_TYPES.SHOP:
			_draw_shop_icon(center, icon_color)
		LocationData.LOCATION_TYPES.REST_SITE:
			_draw_rest_icon(center, icon_color)
		_:
			_draw_combat_icon(center, icon_color, 1.0)

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

func _draw_combat_icon(center: Vector2, color: Color, scale: float) -> void:
	var radius: float = 7.5 * scale
	var face_center: Vector2 = center + Vector2(0.0, 3.0)
	draw_arc(face_center, radius, 0.0, TAU, 36, color, 1.5, true)
	draw_line(face_center + Vector2(-5.0, -4.0) * scale, face_center + Vector2(-12.0, -10.0) * scale, color, 1.5, true)
	draw_line(face_center + Vector2(-12.0, -10.0) * scale, face_center + Vector2(-10.0, -1.0) * scale, color, 1.5, true)
	draw_line(face_center + Vector2(5.0, -4.0) * scale, face_center + Vector2(12.0, -10.0) * scale, color, 1.5, true)
	draw_line(face_center + Vector2(12.0, -10.0) * scale, face_center + Vector2(10.0, -1.0) * scale, color, 1.5, true)
	draw_circle(face_center + Vector2(-3.0, -1.0) * scale, 1.2 * scale, color)
	draw_circle(face_center + Vector2(3.0, -1.0) * scale, 1.2 * scale, color)
	draw_line(face_center + Vector2(-3.0, 4.0) * scale, face_center + Vector2(3.0, 4.0) * scale, color, 1.3, true)

func _draw_miniboss_mark(center: Vector2, color: Color) -> void:
	draw_line(center + Vector2(-5.0, -13.0), center + Vector2(0.0, -17.0), color, 1.4, true)
	draw_line(center + Vector2(0.0, -17.0), center + Vector2(5.0, -13.0), color, 1.4, true)

func _draw_boss_icon(center: Vector2, color: Color) -> void:
	var face_center: Vector2 = center + Vector2(0.0, 3.0)
	draw_arc(face_center, 10.5, 0.0, TAU, 40, color, 1.8, true)
	draw_line(face_center + Vector2(-7.0, -5.0), face_center + Vector2(-16.0, -13.0), color, 1.8, true)
	draw_line(face_center + Vector2(-16.0, -13.0), face_center + Vector2(-14.0, 0.0), color, 1.8, true)
	draw_line(face_center + Vector2(7.0, -5.0), face_center + Vector2(16.0, -13.0), color, 1.8, true)
	draw_line(face_center + Vector2(16.0, -13.0), face_center + Vector2(14.0, 0.0), color, 1.8, true)
	draw_line(face_center + Vector2(-7.0, -11.0), face_center + Vector2(-3.0, -16.0), color, 1.6, true)
	draw_line(face_center + Vector2(-3.0, -16.0), face_center + Vector2(0.0, -11.0), color, 1.6, true)
	draw_line(face_center + Vector2(0.0, -11.0), face_center + Vector2(3.0, -16.0), color, 1.6, true)
	draw_line(face_center + Vector2(3.0, -16.0), face_center + Vector2(7.0, -11.0), color, 1.6, true)
	draw_circle(face_center + Vector2(-4.0, -1.0), 1.4, color)
	draw_circle(face_center + Vector2(4.0, -1.0), 1.4, color)
	draw_line(face_center + Vector2(-4.0, 5.0), face_center + Vector2(4.0, 5.0), color, 1.4, true)

func _draw_treasure_icon(center: Vector2, color: Color) -> void:
	var body: Rect2 = Rect2(center + Vector2(-11.0, -2.0), Vector2(22.0, 13.0))
	draw_rect(body, color, false, 1.6)
	draw_line(center + Vector2(-9.0, -2.0), center + Vector2(-6.0, -8.0), color, 1.6, true)
	draw_line(center + Vector2(-6.0, -8.0), center + Vector2(6.0, -8.0), color, 1.6, true)
	draw_line(center + Vector2(6.0, -8.0), center + Vector2(9.0, -2.0), color, 1.6, true)
	draw_line(center + Vector2(0.0, -8.0), center + Vector2(0.0, 11.0), color, 1.2, true)
	draw_rect(Rect2(center + Vector2(-2.0, 3.0), Vector2(4.0, 4.0)), color, false, 1.2)

func _draw_shop_icon(center: Vector2, color: Color) -> void:
	draw_line(center + Vector2(-6.0, -10.0), center + Vector2(6.0, -10.0), color, 1.5, true)
	draw_line(center + Vector2(-6.0, -10.0), center + Vector2(-10.0, 1.0), color, 1.5, true)
	draw_line(center + Vector2(6.0, -10.0), center + Vector2(10.0, 1.0), color, 1.5, true)
	draw_arc(center + Vector2(0.0, 3.0), 10.0, 0.0, TAU, 36, color, 1.6, true)
	draw_circle(center + Vector2(4.0, 5.0), 3.0, Color(color.r, color.g, color.b, color.a * 0.35))
	draw_arc(center + Vector2(4.0, 5.0), 3.0, 0.0, TAU, 20, color, 1.0, true)

func _draw_rest_icon(center: Vector2, color: Color) -> void:
	draw_line(center + Vector2(-10.0, 11.0), center + Vector2(9.0, 6.0), color, 1.5, true)
	draw_line(center + Vector2(-9.0, 6.0), center + Vector2(10.0, 11.0), color, 1.5, true)
	draw_line(center + Vector2(0.0, -11.0), center + Vector2(-6.0, 2.0), color, 1.6, true)
	draw_line(center + Vector2(-6.0, 2.0), center + Vector2(0.0, 8.0), color, 1.6, true)
	draw_line(center + Vector2(0.0, 8.0), center + Vector2(6.0, 2.0), color, 1.6, true)
	draw_line(center + Vector2(6.0, 2.0), center + Vector2(0.0, -11.0), color, 1.6, true)
	draw_line(center + Vector2(1.0, -4.0), center + Vector2(-2.0, 4.0), color, 1.2, true)
	draw_line(center + Vector2(-2.0, 4.0), center + Vector2(2.0, 4.0), color, 1.2, true)
