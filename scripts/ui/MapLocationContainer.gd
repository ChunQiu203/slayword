extends Control
class_name MapLocationContainer

const ROUTE_COLOR: Color = Color(0.24, 0.27, 0.27, 0.38)
const ROUTE_ACTIVE_COLOR: Color = Color(0.12, 0.20, 0.22, 0.78)
const ROUTE_VISITED_COLOR: Color = Color(0.18, 0.23, 0.22, 0.55)
const DASH_LENGTH: float = 7.0
const DASH_GAP: float = 7.0
const ROUTE_WIDTH: float = 2.0
## Chord length fraction used to offset the quadratic control point (perpendicular bulge).
const ROUTE_CURVE_BULGE: float = 0.16
const ROUTE_CURVE_BULGE_MIN: float = 5.0
const ROUTE_CURVE_BULGE_MAX: float = 26.0
const ROUTE_CURVE_SAMPLES_MIN: int = 14
const ROUTE_CURVE_SAMPLES_MAX: int = 42

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
		_draw_dashed_curved_route(
			connection.from_point,
			connection.to_point,
			color,
			connection.from_id,
			connection.to_id
		)


func _get_route_color(from_id: String, to_id: String) -> Color:
	if from_id == current_location_id and next_location_ids.has(to_id):
		return ROUTE_ACTIVE_COLOR
	if visited_location_ids.has(from_id) and visited_location_ids.has(to_id):
		return ROUTE_VISITED_COLOR
	return ROUTE_COLOR


func _quad_bezier(p0: Vector2, p1: Vector2, p2: Vector2, t: float) -> Vector2:
	var omt: float = 1.0 - t
	return (omt * omt * p0) + (2.0 * omt * t * p1) + (t * t * p2)


func _curve_control_point(from_point: Vector2, to_point: Vector2, from_id: String, to_id: String) -> Vector2:
	var chord: Vector2 = to_point - from_point
	var chord_len: float = chord.length()
	if chord_len < 0.5:
		return (from_point + to_point) * 0.5
	var mid: Vector2 = (from_point + to_point) * 0.5
	var perp: Vector2 = Vector2(-chord.y, chord.x).normalized()
	var side: float = 1.0 if (hash(from_id + "|" + to_id) % 2) == 0 else -1.0
	var bulge: float = clampf(chord_len * ROUTE_CURVE_BULGE, ROUTE_CURVE_BULGE_MIN, ROUTE_CURVE_BULGE_MAX)
	return mid + perp * bulge * side


func _draw_dashed_curved_route(
	from_point: Vector2, to_point: Vector2, color: Color, from_id: String, to_id: String
) -> void:
	var chord_len: float = from_point.distance_to(to_point)
	if chord_len < 1.0:
		return
	# Pure horizontal / vertical: keep straight dashes (cleaner at grid alignment).
	if absf(from_point.x - to_point.x) < 2.5 or absf(from_point.y - to_point.y) < 2.5:
		_draw_dashed_straight(from_point, to_point, color)
		return
	var p0: Vector2 = from_point
	var p2: Vector2 = to_point
	var p1: Vector2 = _curve_control_point(from_point, to_point, from_id, to_id)
	var sample_count: int = clampi(int(chord_len / 3.5), ROUTE_CURVE_SAMPLES_MIN, ROUTE_CURVE_SAMPLES_MAX)
	var pts: PackedVector2Array = PackedVector2Array()
	pts.resize(sample_count + 1)
	for s in range(sample_count + 1):
		var tt: float = float(s) / float(sample_count)
		pts[s] = _quad_bezier(p0, p1, p2, tt)
	_draw_dashed_polyline_arclength(pts, color)


func _draw_dashed_straight(from_point: Vector2, to_point: Vector2, color: Color) -> void:
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


func _draw_dashed_polyline_arclength(points: PackedVector2Array, color: Color) -> void:
	if points.size() < 2:
		return
	var cum: Array[float] = [0.0]
	var total: float = 0.0
	for i in range(points.size() - 1):
		total += points[i].distance_to(points[i + 1])
		cum.append(total)
	if total <= 0.001:
		return
	var u: float = 0.0
	while u < total:
		var dash_end: float = minf(u + DASH_LENGTH, total)
		_draw_arclength_substroke(points, cum, u, dash_end, color)
		u = dash_end + DASH_GAP


func _point_at_arc_length(points: PackedVector2Array, cum: Array[float], u: float) -> Vector2:
	var umax: float = cum[cum.size() - 1]
	u = clampf(u, 0.0, umax)
	if u >= umax - 0.0001:
		return points[points.size() - 1]
	var idx: int = 0
	while idx < points.size() - 2 and cum[idx + 1] < u:
		idx += 1
	var seg_start: float = cum[idx]
	var seg_end: float = cum[idx + 1]
	var seg_len: float = seg_end - seg_start
	if seg_len <= 0.0001:
		return points[idx]
	var t: float = (u - seg_start) / seg_len
	return points[idx].lerp(points[idx + 1], t)


func _draw_arclength_substroke(
	points: PackedVector2Array, cum: Array[float], u0: float, u1: float, color: Color
) -> void:
	if u1 <= u0 + 0.0001:
		return
	var step: float = 2.0
	var p_prev: Vector2 = _point_at_arc_length(points, cum, u0)
	var w: float = u0
	while w < u1 - 0.0001:
		w = minf(w + step, u1)
		var p_next: Vector2 = _point_at_arc_length(points, cum, w)
		draw_line(p_prev, p_next, color, ROUTE_WIDTH, true)
		p_prev = p_next
