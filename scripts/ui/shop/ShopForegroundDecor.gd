extends Control
class_name ShopForegroundDecor

const WOOD_DARK := Color(0.10, 0.055, 0.035, 0.72)
const WOOD_MID := Color(0.19, 0.105, 0.055, 0.62)
const WOOD_EDGE := Color(0.47, 0.33, 0.16, 0.78)
const CLOTH_DARK := Color(0.23, 0.040, 0.040, 0.64)
const CLOTH_EDGE := Color(0.72, 0.43, 0.18, 0.70)
const MERCHANT_SHADOW := Color(0.025, 0.020, 0.025, 0.62)
const MERCHANT_CLOTH := Color(0.12, 0.18, 0.19, 0.54)


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	if w <= 0.0 or h <= 0.0:
		return
	_draw_canopy(w, h)
	_draw_side_counter(w, h)
	_draw_bottom_counter(w, h)
	_draw_merchant_silhouette(w, h)


func _draw_canopy(w: float, _h: float) -> void:
	var y := 56.0
	var canopy := PackedVector2Array([
		Vector2(w * 0.08, y),
		Vector2(w * 0.92, y),
		Vector2(w * 0.88, y + 48.0),
		Vector2(w * 0.12, y + 48.0),
	])
	draw_colored_polygon(canopy, CLOTH_DARK)
	draw_polyline(PackedVector2Array([
		Vector2(w * 0.08, y),
		Vector2(w * 0.92, y),
		Vector2(w * 0.88, y + 48.0),
		Vector2(w * 0.12, y + 48.0),
		Vector2(w * 0.08, y),
	]), CLOTH_EDGE, 3.0)
	for i in range(7):
		var x0 := lerpf(w * 0.13, w * 0.81, float(i) / 6.0)
		var flap := PackedVector2Array([
			Vector2(x0, y + 45.0),
			Vector2(x0 + w * 0.075, y + 45.0),
			Vector2(x0 + w * 0.037, y + 78.0),
		])
		draw_colored_polygon(flap, Color(0.16, 0.035, 0.035, 0.54))
		draw_polyline(PackedVector2Array([flap[0], flap[1], flap[2], flap[0]]), Color(0.60, 0.39, 0.16, 0.58), 2.0)


func _draw_side_counter(w: float, h: float) -> void:
	var left_post := Rect2(Vector2(w * 0.035, h * 0.20), Vector2(28.0, h * 0.66))
	var right_post := Rect2(Vector2(w * 0.943, h * 0.20), Vector2(28.0, h * 0.66))
	draw_rect(left_post, WOOD_DARK, true)
	draw_rect(right_post, WOOD_DARK, true)
	draw_rect(left_post, WOOD_EDGE, false, 2.0)
	draw_rect(right_post, WOOD_EDGE, false, 2.0)


func _draw_bottom_counter(w: float, h: float) -> void:
	var y := h - 118.0
	var top := PackedVector2Array([
		Vector2(w * 0.06, y),
		Vector2(w * 0.94, y),
		Vector2(w * 0.98, h),
		Vector2(w * 0.02, h),
	])
	draw_colored_polygon(top, WOOD_DARK)
	draw_polyline(PackedVector2Array([
		Vector2(w * 0.06, y),
		Vector2(w * 0.94, y),
		Vector2(w * 0.98, h),
		Vector2(w * 0.02, h),
		Vector2(w * 0.06, y),
	]), WOOD_EDGE, 3.0)
	for i in range(6):
		var x := lerpf(w * 0.10, w * 0.86, float(i) / 5.0)
		draw_line(Vector2(x, y + 10.0), Vector2(x + 28.0, h - 8.0), WOOD_MID, 3.0)
	draw_line(Vector2(w * 0.08, y + 18.0), Vector2(w * 0.92, y + 18.0), Color(0.72, 0.54, 0.25, 0.40), 2.0)


func _draw_merchant_silhouette(w: float, h: float) -> void:
	var base := Vector2(w * 0.115, h - 88.0)
	draw_circle(base + Vector2(0, -76.0), 34.0, MERCHANT_SHADOW)
	var hood := PackedVector2Array([
		base + Vector2(-56.0, -40.0),
		base + Vector2(-24.0, -116.0),
		base + Vector2(30.0, -120.0),
		base + Vector2(62.0, -38.0),
		base + Vector2(44.0, -10.0),
		base + Vector2(-46.0, -8.0),
	])
	draw_colored_polygon(hood, MERCHANT_CLOTH)
	draw_polyline(PackedVector2Array([hood[0], hood[1], hood[2], hood[3], hood[4], hood[5], hood[0]]), Color(0.43, 0.56, 0.55, 0.34), 2.0)
	draw_circle(base + Vector2(-12.0, -82.0), 4.0, Color(0.85, 0.73, 0.32, 0.48))
	draw_circle(base + Vector2(14.0, -82.0), 4.0, Color(0.85, 0.73, 0.32, 0.48))
