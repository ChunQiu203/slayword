## Star Chart gameplay guide — accessible from main menu
extends Control

@onready var title_screen: Control = $%TitleScreen
@onready var back_button: Button = $BackButton
@onready var scroll: ScrollContainer = $ScrollContainer
@onready var content: VBoxContainer = $ScrollContainer/MarginContainer/VBoxContainer

const HOUSE_NAMES: Array[String] = ["黎明", "正午", "黄昏", "夜晚", "智慧", "命运"]
const HOUSE_NAMES_EN: Array[String] = ["Dawn", "Noon", "Dusk", "Night", "Wisdom", "Fate"]
const HOUSE_ICONS: Array[String] = ["☀", "🌤", "🌅", "🌙", "📖", "🎲"]
const HOUSE_COLORS: Array[Color] = [
	Color(1.0, 0.85, 0.2),   # Dawn - gold
	Color(1.0, 0.6, 0.1),    # Noon - orange
	Color(0.7, 0.4, 0.9),    # Dusk - purple
	Color(0.3, 0.5, 1.0),    # Night - blue
	Color(0.2, 0.9, 0.5),    # Wisdom - green
	Color(1.0, 0.3, 0.6),    # Fate - magenta
]

func _ready():
	# Black background behind everything
	var bg := ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.85)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	move_child(bg, 0)

	# Black background for the content area (behind ScrollContainer)
	var content_bg := ColorRect.new()
	content_bg.color = Color(0.05, 0.05, 0.05, 0.9)
	content_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scroll.add_child(content_bg)
	scroll.move_child(content_bg, 0)

	back_button.pressed.connect(_on_back_button_up)
	I18N.locale_changed.connect(_on_locale_changed)
	_build_guide_content()

func _on_back_button_up():
	title_screen.show_main_menu()

func _on_locale_changed(_locale: String):
	_build_guide_content()

func _build_guide_content():
	# Clear existing content
	for child in content.get_children():
		child.queue_free()

	var is_zh := I18N.current_locale == "zh_CN"

	# Title
	_add_section_title("星辰系统" if is_zh else "Star Chart System")
	_add_body_text("星辰系统是占星师角色的核心机制。通过卡牌在星辰图的六种星位中放置星辰，获得被动加成和特殊效果。" if is_zh else "The Star Chart is the Astrologer's core mechanic. Place Stars into six star slots via cards to gain passive bonuses and special effects.")

	# --- Houses section ---
	_add_section_title("六大星位" if is_zh else "Six Star Slots")
	_add_body_text("星辰图有六种星位，每种星位对应一种被动效果。只要该星位有星辰（≥1颗），该效果每回合自动生效。" if is_zh else "The Star Chart has six star slots. Each slot provides a passive bonus that activates every turn as long as it has at least 1 Star.")

	for i in range(6):
		var house_name: String = HOUSE_NAMES[i] if is_zh else HOUSE_NAMES_EN[i]
		var icon: String = HOUSE_ICONS[i]
		var color: Color = HOUSE_COLORS[i]
		var desc: String = _get_house_description(i, is_zh)
		_add_house_entry(icon, house_name, color, desc)

	# --- Singularity ---
	_add_section_title("奇点增幅" if is_zh else "Singularity Amplification")
	_add_body_text("当玩家拥有「奇点」状态且全场恰好只有1颗星辰时，黎明/正午/黄昏/夜晚的被动效果倍率提升至×3（+3能量/+6伤害/+6格挡/+3抽牌）。" if is_zh else "When the player has the Singularity status and exactly 1 Star on the chart, Dawn/Noon/Dusk/Night passive bonuses are tripled (+3 energy / +6 damage / +6 block / +3 draw).")

	# --- Alignment section ---
	_add_section_title("星位共鸣（≥2颗星）" if is_zh else "Alignment (≥2 Stars)")
	_add_body_text("当某个星位拥有≥2颗星辰时，可以通过卡牌触发「星位共鸣」，向手牌中加入一张0费的共鸣卡牌。" if is_zh else "When a star slot has ≥2 Stars, you can trigger Alignment via cards to add a 0-cost Alignment card to your hand.")

	for i in range(6):
		var house_name: String = HOUSE_NAMES[i] if is_zh else HOUSE_NAMES_EN[i]
		var card_desc: String = _get_alignment_description(i, is_zh)
		_add_compact_entry(HOUSE_ICONS[i], house_name, HOUSE_COLORS[i], card_desc)

	# --- Eclipse section ---
	_add_section_title("日蚀（≥4种星位有星）" if is_zh else "Eclipse (≥4 star slots occupied)")
	_add_body_text("当场上至少4种星位拥有星辰时，可以触发「日蚀」。触发时获得0费「日蚀爆发」卡牌加入手牌。" if is_zh else "When at least 4 star slots have Stars, you can trigger Eclipse. This adds a 0-cost Eclipse Burst card to your hand.")
	_add_body_text("打出「日蚀爆发」时：每种星位各消耗1颗星辰，然后获得3点能量、抽5张牌、对所有敌人造成15点伤害。" if is_zh else "When you play Eclipse Burst: consume 1 Star from each star slot, then gain 3 energy, draw 5 cards, and deal 15 damage to all enemies.")

	# --- Place & Consume ---
	_add_section_title("放星与吃星" if is_zh else "Placing & Consuming Stars")
	_add_body_text("• 放星：通过卡牌效果在指定星位放置星辰（-1为随机星位）\n• 吃星：消耗指定星位的星辰来触发卡牌效果（-1为自动从星最多的星位消耗）\n• 吃星缩放：部分卡牌的伤害/格挡会根据消耗的星辰数量增加（每颗星+X）" if is_zh else "• Place Stars: Cards add Stars to a specific star slot (-1 = random slot)\n• Consume Stars: Cards remove Stars from a slot to trigger effects (-1 = auto-pick the most populated slot)\n• Consume Scaling: Some cards gain +X damage/block per Star consumed")

	# --- Validator section ---
	_add_section_title("条件验证" if is_zh else "Condition Validators")
	_add_body_text("部分卡牌需要满足星辰条件才能打出：\n• 全场最少星数\n• 某星位最少星数\n• 至少几个星位有星" if is_zh else "Some cards require Star conditions to play:\n• Minimum total Stars\n• Minimum Stars in a specific star slot\n• Minimum number of occupied star slots")

func _add_section_title(text: String):
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 30)
	label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.8))
	label.add_theme_constant_override("outline_size", 2)
	content.add_child(label)

	var sep := HSeparator.new()
	sep.add_theme_constant_override("separation", 8)
	content.add_child(sep)

func _add_body_text(text: String):
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color(0.92, 0.89, 0.82))
	content.add_child(label)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	content.add_child(spacer)

func _add_house_entry(icon: String, name: String, color: Color, description: String):
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(hbox)

	var icon_label := Label.new()
	icon_label.text = icon
	icon_label.add_theme_font_size_override("font_size", 30)
	icon_label.custom_minimum_size = Vector2(40, 0)
	hbox.add_child(icon_label)

	var info_vbox := VBoxContainer.new()
	info_vbox.add_theme_constant_override("separation", 2)
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)

	var name_label := Label.new()
	name_label.text = name
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", 24)
	name_label.add_theme_color_override("font_color", color)
	info_vbox.add_child(name_label)

	var desc_label := Label.new()
	desc_label.text = description
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desc_label.add_theme_font_size_override("font_size", 22)
	desc_label.add_theme_color_override("font_color", Color(0.82, 0.8, 0.75))
	info_vbox.add_child(desc_label)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	content.add_child(spacer)

func _add_compact_entry(icon: String, name: String, color: Color, description: String):
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_child(hbox)

	var icon_label := Label.new()
	icon_label.text = icon
	icon_label.add_theme_font_size_override("font_size", 26)
	icon_label.custom_minimum_size = Vector2(36, 0)
	hbox.add_child(icon_label)

	var info_vbox := VBoxContainer.new()
	info_vbox.add_theme_constant_override("separation", 2)
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(info_vbox)

	var name_label := Label.new()
	name_label.text = name
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", 22)
	name_label.add_theme_color_override("font_color", color)
	info_vbox.add_child(name_label)

	var desc_label := Label.new()
	desc_label.text = description
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	desc_label.add_theme_font_size_override("font_size", 20)
	desc_label.add_theme_color_override("font_color", Color(0.82, 0.8, 0.75))
	info_vbox.add_child(desc_label)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	content.add_child(spacer)

func _get_house_description(i: int, is_zh: bool) -> String:
	if is_zh:
		match i:
			0: return "每回合开始 +1 能量"
			1: return "所有攻击 +2 伤害"
			2: return "所有技能 +2 格挡"
			3: return "每回合多抽 1 张牌"
			4: return "每回合第一张打出的牌免费复制一次"
			5: return "每回合随机获得：+1能量 / +2伤害 / +2格挡 / +1抽牌"
		return ""
	else:
		match i:
			0: return "+1 energy at turn start"
			1: return "+2 damage to all attacks"
			2: return "+2 block from all skills"
			3: return "+1 card draw per turn"
			4: return "First card played each turn is duplicated for free"
			5: return "Random bonus each turn: +1 energy / +2 damage / +2 block / +1 draw"
		return ""

func _get_alignment_description(i: int, is_zh: bool) -> String:
	if is_zh:
		match i:
			0: return "黎明祝福 — 获得+2能量"
			1: return "正午之怒 — 对所有敌人造成伤害"
			2: return "黄昏守护 — 获得格挡"
			3: return "夜晚低语 — 抽取卡牌"
			4: return "智慧洞察 — 升级一张卡牌"
			5: return "命运谕令 — 触发所有效果（减半）"
		return ""
	else:
		match i:
			0: return "Dawn Blessing — Gain +2 energy"
			1: return "Noon Fury — Deal AOE damage"
			2: return "Dusk Guard — Gain block"
			3: return "Night Whisper — Draw cards"
			4: return "Wisdom Insight — Upgrade a card"
			5: return "Fate Decree — All effects at half"
		return ""
