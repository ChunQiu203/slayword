extends Button
class_name VocabMcOptionButton

## 由 WordReviewOverlay._apply_panel_layout 写入，使 Grid 列宽不随长文案无限变宽。
var layout_content_width: float = 0.0

func _ready() -> void:
	clip_text = true
	text_overrun_behavior = TextServer.OVERRUN_TRIM_WORD_ELLIPSIS
	autowrap_mode = TextServer.AUTOWRAP_OFF
	alignment = HORIZONTAL_ALIGNMENT_CENTER


func _get_minimum_size() -> Vector2:
	# Button 在 GDScript 里不能 super._get_minimum_size()；宽度用列宽锁死，高度用主题字号估算一行。
	var fh: float = float(get_theme_font_size("font_size", "Button"))
	var h: float = maxf(custom_minimum_size.y, fh + 14.0)
	var w: float = layout_content_width
	if w <= 0.0:
		w = maxf(custom_minimum_size.x, 160.0)
	return Vector2(w, h)
