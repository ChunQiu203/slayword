extends RefCounted
class_name MapRouteConnection

var from_point: Vector2 = Vector2.ZERO
var to_point: Vector2 = Vector2.ZERO
var from_id: String = ""
var to_id: String = ""


func _init(
	_from_point: Vector2 = Vector2.ZERO,
	_to_point: Vector2 = Vector2.ZERO,
	_from_id: String = "",
	_to_id: String = ""
) -> void:
	from_point = _from_point
	to_point = _to_point
	from_id = _from_id
	to_id = _to_id
