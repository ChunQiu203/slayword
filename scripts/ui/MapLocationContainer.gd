extends Control
class_name MapLocationContainer

const ROUTE_COLOR: Color = Color(0.24, 0.27, 0.27, 0.38)
const ROUTE_ACTIVE_COLOR: Color = Color(0.12, 0.20, 0.22, 0.78)
const ROUTE_VISITED_COLOR: Color = Color(0.18, 0.23, 0.22, 0.55)
const DASH_LENGTH: float = 7.0
const DASH_GAP: float = 7.0
const ROUTE_WIDTH: float = 2.0

var route_connections: Array[MapRouteConnection] = []
var current_location_id: String = ""
var next_location_ids: Array[String] = []
var visited_location_ids: Array[String] = []


func set_route_data(
	_connections: Array[MapRouteConnection],
	_current_location_id: String,
	_next_location_ids: Array[String],
	_visited_location_ids: Array[String]
) -> void:
	route_connections = _connections
	current_location_id = _current_location_id
	next_location_ids = _next_location_ids
	visited_location_ids = _visited_location_ids
	queue_redraw()


func _draw() -> void:
	for connection: MapRouteConnection in route_connections:
		var color: Color = _get_route_color(connection.from_id, connection.to_id)
		_draw_dashed_route(connection.from_point, connection.to_point, color)


func _get_route_color(from_id: String, to_id: String) -> Color:
	if from_id == current_location_id and next_location_ids.has(to_id):
		return ROUTE_ACTIVE_COLOR
	if visited_location_ids.has(from_id) and visited_location_ids.has(to_id):
		return ROUTE_VISITED_COLOR
	return ROUTE_COLOR


func _draw_dashed_route(from_point: Vector2, to_point: Vector2, color: Color) -> void:
	var delta: Vector2 = to_point - from_point
	var distance: float = delta.length()
	if distance <= 0.0:
		return
	
	var direction: Vector2 = delta / distance
	var cursor: float = 0.0
	while cursor < distance:
		var segment_end: float = cursor + DASH_LENGTH
		if segment_end > distance:
			segment_end = distance
		draw_line(
			from_point + (direction * cursor),
			from_point + (direction * segment_end),
			color,
			ROUTE_WIDTH,
			true
		)
		cursor += DASH_LENGTH + DASH_GAP
