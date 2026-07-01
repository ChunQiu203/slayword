extends BaseCustomUI
class_name StarBonusUI
## Shows star chart passive bonuses and combat status effects as icons below the player character.
## Click an icon to toggle its description tooltip.

const BONUS_ICONS: Array[Dictionary] = [
	{"key": "bonus_energy", "name": "能量", "desc": "每回合+1能量", "color": Color(1.0, 0.85, 0.4), "icon": "res://external/sprites/ui/ui_bonus_energy.svg"},
	{"key": "bonus_damage", "name": "伤害", "desc": "所有攻击+4伤害", "color": Color(1.0, 0.45, 0.2), "icon": "res://external/sprites/ui/ui_bonus_damage.svg"},
	{"key": "bonus_block", "name": "格挡", "desc": "所有技能+4格挡", "color": Color(0.7, 0.35, 0.85), "icon": "res://external/sprites/ui/ui_bonus_block.svg"},
	{"key": "bonus_draw", "name": "抽牌", "desc": "每回合+1抽牌", "color": Color(0.25, 0.35, 0.95), "icon": "res://external/sprites/ui/ui_bonus_draw.svg"},
	{"key": "bonus_duplicate", "name": "复制", "desc": "每回合首张牌复制", "color": Color(0.25, 0.9, 0.65), "icon": "res://external/sprites/ui/ui_bonus_duplicate.svg"},
]

const STATUS_ICONS: Array[Dictionary] = [
	{"status": "status_effect_weaken", "name": "虚弱", "desc": "伤害×0.75", "color": Color(0.6, 0.6, 0.6), "icon": "res://external/sprites/status_effects/status_effect_weaken.svg"},
	{"status": "status_effect_vulnerable", "name": "易伤", "desc": "受到伤害×1.5", "color": Color(1.0, 0.3, 0.3), "icon": "res://external/sprites/status_effects/status_effect_vulnerable.svg"},
	{"status": "status_effect_damage_increase", "name": "力量", "desc": "攻击+伤害", "color": Color(1.0, 0.5, 0.0), "icon": "res://external/sprites/status_effects/status_effect_damage_increase.svg"},
	{"status": "status_effect_singularity", "name": "奇点", "desc": "被动三倍加成", "color": Color(1.0, 1.0, 0.0), "icon": "res://external/sprites/ui/ui_status_singularity.svg"},
]

var _icon_buttons: Array[Button] = []
var _hbox: HBoxContainer
var _tooltip: Label
var _active_icon: int = -1

const ICON_SIZE := Vector2(36, 36)

func init(_custom_ui_object_id: String, _parent_combatant: BaseCombatant) -> void:
	super(_custom_ui_object_id, _parent_combatant)
	_setup_ui()
	if not Signals.star_placed.is_connected(_on_star_changed):
		Signals.star_placed.connect(_on_star_changed)
		Signals.star_consumed.connect(_on_star_changed)
		Signals.eclipse_triggered.connect(_on_eclipse)

func _setup_ui() -> void:
	anchors_preset = Control.PRESET_CENTER_BOTTOM
	offset_left = -120
	offset_right = 120
	offset_top = 130
	offset_bottom = 180

	_hbox = HBoxContainer.new()
	_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_hbox.add_theme_constant_override("separation", 8)
	_hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_hbox)

	_tooltip = Label.new()
	_tooltip.text = ""
	_tooltip.add_theme_font_size_override("font_size", 20)
	_tooltip.add_theme_color_override("font_color", Color.WHITE)
	_tooltip.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	_tooltip.add_theme_constant_override("shadow_offset_x", 1)
	_tooltip.add_theme_constant_override("shadow_offset_y", 1)
	_tooltip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tooltip.visible = false
	_tooltip.modulate = Color(1, 1, 1, 0)
	add_child(_tooltip)

	for i in range(BONUS_ICONS.size()):
		var btn := _create_icon_button(BONUS_ICONS[i]["icon"], i)
		_hbox.add_child(btn)
		_icon_buttons.append(btn)

	for i in range(STATUS_ICONS.size()):
		var btn := _create_icon_button(STATUS_ICONS[i]["icon"], BONUS_ICONS.size() + i)
		_hbox.add_child(btn)
		_icon_buttons.append(btn)

func _create_icon_button(icon_path: String, idx: int) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = ICON_SIZE
	btn.size = ICON_SIZE
	btn.visible = false
	btn.modulate = Color(1, 1, 1, 0)

	var style_normal := StyleBoxFlat.new()
	style_normal.bg_color = Color(0.15, 0.15, 0.15, 0.6)
	style_normal.set_corner_radius_all(6)
	style_normal.set_content_margin_all(4)
	btn.add_theme_stylebox_override("normal", style_normal)

	var style_hover := StyleBoxFlat.new()
	style_hover.bg_color = Color(0.3, 0.3, 0.3, 0.7)
	style_hover.set_corner_radius_all(6)
	style_hover.set_content_margin_all(4)
	btn.add_theme_stylebox_override("hover", style_hover)

	var tex := TextureRect.new()
	tex.texture = load(icon_path)
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tex.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(tex)

	btn.pressed.connect(func(): _toggle_tooltip(idx))
	return btn

func _toggle_tooltip(idx: int) -> void:
	if _active_icon == idx:
		_active_icon = -1
		var tw := create_tween()
		tw.tween_property(_tooltip, "modulate", Color(1, 1, 1, 0), 0.2)
		tw.tween_property(_tooltip, "position:y", _tooltip.position.y + 5, 0.2)
		tw.tween_callback(func(): _tooltip.visible = false)
	else:
		_active_icon = idx
		var desc: String = ""
		var color: Color = Color.WHITE
		if idx < BONUS_ICONS.size():
			desc = BONUS_ICONS[idx]["name"] + ": " + BONUS_ICONS[idx]["desc"]
			color = BONUS_ICONS[idx]["color"]
		else:
			var status_idx := idx - BONUS_ICONS.size()
			desc = STATUS_ICONS[status_idx]["name"] + ": " + STATUS_ICONS[status_idx]["desc"]
			color = STATUS_ICONS[status_idx]["color"]
		_tooltip.text = desc
		_tooltip.add_theme_color_override("font_color", color)
		_tooltip.visible = true
		_tooltip.modulate = Color(1, 1, 1, 0)
		_tooltip.position = Vector2(0, -25)
		var tw := create_tween()
		tw.tween_property(_tooltip, "modulate", Color(1, 1, 1, 1), 0.2)
		tw.parallel().tween_property(_tooltip, "position:y", _tooltip.position.y - 5, 0.2)

func _on_star_changed(_house: int = -1, _count: int = 0) -> void:
	_refresh()

func _on_eclipse(_total: int) -> void:
	_refresh()
	_active_icon = -1
	_tooltip.visible = false

func _refresh() -> void:
	var bonuses := StarChartHelper.get_house_passive_bonus()
	var player := Global.get_player()

	for i in range(BONUS_ICONS.size()):
		var bonus_key: String = BONUS_ICONS[i]["key"]
		var has_bonus: bool = false
		if bonus_key == "bonus_duplicate":
			has_bonus = bonuses.get(bonus_key, false)
		else:
			has_bonus = bonuses.get(bonus_key, 0) > 0

		var btn: Button = _icon_buttons[i]
		if has_bonus and not btn.visible:
			btn.visible = true
			btn.modulate = Color(1, 1, 1, 0)
			var tw := create_tween()
			tw.tween_property(btn, "modulate", Color(1, 1, 1, 1), 0.2)
		elif not has_bonus and btn.visible:
			var tw := create_tween()
			tw.tween_property(btn, "modulate", Color(1, 1, 1, 0), 0.15)
			tw.tween_callback(func(): btn.visible = false)

	for i in range(STATUS_ICONS.size()):
		var status_id: String = STATUS_ICONS[i]["status"]
		var has_status: bool = false
		if player != null:
			has_status = player.get_status_charges(status_id) > 0

		var btn: Button = _icon_buttons[BONUS_ICONS.size() + i]
		if has_status and not btn.visible:
			btn.visible = true
			btn.modulate = Color(1, 1, 1, 0)
			var tw := create_tween()
			tw.tween_property(btn, "modulate", Color(1, 1, 1, 1), 0.2)
		elif not has_status and btn.visible:
			var tw := create_tween()
			tw.tween_property(btn, "modulate", Color(1, 1, 1, 0), 0.15)
			tw.tween_callback(func(): btn.visible = false)
