extends BaseCustomUI
## Renders the Astrologer's Star Chart - 6 Houses with star counts.

const HOUSE_NAMES := ["Dawn", "Noon", "Dusk", "Night", "Wisdom", "Fate"]
const HOUSE_COLORS := [
	Color(1.0, 0.85, 0.4), Color(1.0, 0.4, 0.2), Color(0.7, 0.4, 0.8),
	Color(0.2, 0.3, 0.9), Color(0.3, 0.9, 0.7), Color(0.9, 0.2, 0.9),
]
var _star_labels: Array[Label] = []

func init(custom_ui_object_id: String, _parent_combatant: BaseCombatant) -> void:
	super(custom_ui_object_id, _parent_combatant)
	_build_ui()
	Signals.star_placed.connect(_refresh)
	Signals.star_consumed.connect(_refresh2)
	Signals.stars_rotated.connect(_refresh0)
	Signals.eclipse_triggered.connect(_refresh0)
	_refresh()

func _build_ui() -> void:
	var vb := VBoxContainer.new()
	vb.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	vb.position = Vector2(-160, 60)
	add_child(vb)
	var tl := Label.new()
	tl.text = "Star Chart"
	tl.add_theme_color_override("font_color", Color(0.9, 0.85, 0.5))
	tl.add_theme_font_size_override("font_size", 14)
	vb.add_child(tl)
	var grid := GridContainer.new()
	grid.columns = 2
	vb.add_child(grid)
	for i in range(6):
		var nl := Label.new()
		nl.text = HOUSE_NAMES[i]
		nl.add_theme_color_override("font_color", HOUSE_COLORS[i])
		nl.add_theme_font_size_override("font_size", 11)
		grid.add_child(nl)
		var cl := Label.new()
		cl.text = "0"
		cl.add_theme_font_size_override("font_size", 13)
		grid.add_child(cl)
		_star_labels.append(cl)

func _refresh(_h: int = -1) -> void:
	var chart = StarChartHelper.get_star_chart()
	for i in range(6):
		if i < _star_labels.size():
			_star_labels[i].text = str(int(chart[i]))
			_star_labels[i].add_theme_color_override("font_color",
				Color.YELLOW if int(chart[i]) >= 2 else Color.WHITE)

func _refresh2(_h: int, _c: int) -> void: _refresh()
func _refresh0(_t: int = 0) -> void: _refresh()
