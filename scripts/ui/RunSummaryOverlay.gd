extends Control

@onready var victory_label = $VictoryLabel
@onready var defeat_label = $DefeatLabel
@onready var end_run_button = $EndRunButton
@onready var view_statistics_button = $ViewStatisticsButton
@onready var quit_label = $QuitLabel
@onready var prompt_label = $PromptLabel
@onready var background = $Background
@onready var legacy_panel = $Background2

var player_run_end_state: int = Global.RUN_ENDS.QUIT # store if the player won or lost in the ui
var _showing_player_ended_summary: bool = false # track if we're showing summary for player-ended run
var _summary_margin: MarginContainer
var _result_mark_label: Label
var _status_label: Label
var _title_label: Label
var _hint_label: Label
var _death_reason_label: Label
var _stat_labels: Dictionary = {}
var _stats_grid: GridContainer
var _button_grid: GridContainer
var _layout_built: bool = false

func _ready():
	_build_mobile_layout()
	end_run_button.pressed.connect(_on_end_run_button_up)
	view_statistics_button.pressed.connect(_on_view_statistics_button_up)
	Signals.combat_ended.connect(_on_combat_ended)
	Signals.run_started.connect(_on_run_started)
	Signals.run_ended.connect(_on_run_ended)
	Signals.run_victory.connect(_on_run_victory)
	Signals.player_death_animation_finished.connect(_on_player_death_animation_finished)
	Signals.run_ended_by_player.connect(_on_run_ended_by_player)
	I18N.locale_changed.connect(_on_locale_changed)
	_refresh_summary_display()

func _on_combat_ended():
	if Global.is_end_of_run():
		visible = true
		Signals.run_victory.emit()

func _on_run_started():
	visible = false
	_showing_player_ended_summary = false
		
func _on_run_ended():
	# Don't hide if we're showing a player-ended summary
	if not _showing_player_ended_summary:
		visible = false
	
func _on_run_victory():
	_show_summary(Global.RUN_ENDS.VICTORY)
	
func _on_player_death_animation_finished(_player: Player):
	_show_summary(Global.RUN_ENDS.LOSS)

func _on_view_statistics_button_up():
	# Show detailed statistics
	visible = false
	_showing_player_ended_summary = false
	var stats = Global.player_data.get_statistics_for_summary()
	var result_text = "VICTORY" if player_run_end_state == Global.RUN_ENDS.VICTORY else "DEFEAT" if player_run_end_state == Global.RUN_ENDS.LOSS else "QUIT"

	# Get the statistics overlay and show it
	var stats_overlay = get_node_or_null("/root/Root/RunScreen/RunStatisticsOverlay")
	if stats_overlay:
		stats_overlay.show_statistics(
			result_text,
			stats["floor_reached"],
			stats["cards_obtained"],
			stats["enemies_defeated"],
			stats["damage_taken"],
			stats["words_reviewed"],
			stats["words_correct"],
			stats["death_reason"]
		)

func _on_run_ended_by_player(run_end_state: int) -> void:
	# Show the summary overlay when player manually ends the run
	_showing_player_ended_summary = true

	match run_end_state:
		Global.RUN_ENDS.QUIT:
			_show_summary(Global.RUN_ENDS.QUIT)
		Global.RUN_ENDS.LOSS:
			_show_summary(Global.RUN_ENDS.LOSS)

func _on_end_run_button_up():
	visible = false
	_showing_player_ended_summary = false
	# Hide RunScreen when returning to main menu
	var run_screen = get_node_or_null("/root/Root/RunScreen")
	if run_screen:
		run_screen.visible = false
	Global.end_run(player_run_end_state)


func _build_mobile_layout() -> void:
	if _layout_built:
		return
	_layout_built = true
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	if background:
		background.set_anchors_preset(Control.PRESET_FULL_RECT)
		background.color = Color(0.0, 0.0, 0.0, 0.72)
		background.mouse_filter = Control.MOUSE_FILTER_STOP
	if legacy_panel:
		legacy_panel.visible = false
	victory_label.visible = false
	defeat_label.visible = false
	quit_label.visible = false
	prompt_label.visible = false

	_summary_margin = MarginContainer.new()
	_summary_margin.name = "SummaryCardMargin"
	_summary_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_summary_margin)

	var center := CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_summary_margin.add_child(center)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(420, 430)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	card.add_theme_stylebox_override("panel", SlayMobileStyle.panel_style(Color(0.045, 0.052, 0.050, 0.96), SlayMobileStyle.BORDER_GOLD, 10))
	center.add_child(card)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_child(root)

	var header := HBoxContainer.new()
	header.alignment = BoxContainer.ALIGNMENT_CENTER
	header.add_theme_constant_override("separation", 12)
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(header)

	var mark_panel := PanelContainer.new()
	mark_panel.custom_minimum_size = Vector2(76, 76)
	mark_panel.add_theme_stylebox_override("panel", SlayMobileStyle.panel_style(Color(0.015, 0.018, 0.017, 0.78), Color(0.72, 0.58, 0.30, 0.95), 10))
	header.add_child(mark_panel)

	_result_mark_label = Label.new()
	SlayMobileStyle.style_label(_result_mark_label, 38, SlayMobileStyle.TEXT_MAIN, HORIZONTAL_ALIGNMENT_CENTER)
	_result_mark_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mark_panel.add_child(_result_mark_label)

	var title_box := VBoxContainer.new()
	title_box.add_theme_constant_override("separation", 4)
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_box)

	_status_label = Label.new()
	SlayMobileStyle.style_label(_status_label, 17, SlayMobileStyle.TEXT_MUTED)
	title_box.add_child(_status_label)

	_title_label = Label.new()
	SlayMobileStyle.style_label(_title_label, 32, SlayMobileStyle.TEXT_MAIN)
	title_box.add_child(_title_label)

	_hint_label = Label.new()
	SlayMobileStyle.style_label(_hint_label, 18, SlayMobileStyle.TEXT_MUTED)
	_hint_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(_hint_label)

	_stats_grid = GridContainer.new()
	_stats_grid.columns = 4
	_stats_grid.add_theme_constant_override("h_separation", 10)
	_stats_grid.add_theme_constant_override("v_separation", 10)
	_stats_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(_stats_grid)
	_add_stat_chip("floor")
	_add_stat_chip("enemies")
	_add_stat_chip("cards")
	_add_stat_chip("vocab")

	_death_reason_label = Label.new()
	SlayMobileStyle.style_label(_death_reason_label, 17, SlayMobileStyle.TEXT_WARN)
	_death_reason_label.visible = false
	root.add_child(_death_reason_label)

	_button_grid = GridContainer.new()
	_button_grid.columns = 2
	_button_grid.add_theme_constant_override("h_separation", 12)
	_button_grid.add_theme_constant_override("v_separation", 10)
	_button_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.add_child(_button_grid)

	view_statistics_button.reparent(_button_grid, false)
	view_statistics_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	view_statistics_button.custom_minimum_size = Vector2(0, 66)
	SlayMobileStyle.style_button(view_statistics_button, "gold", 21)

	end_run_button.reparent(_button_grid, false)
	end_run_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	end_run_button.custom_minimum_size = Vector2(0, 66)
	SlayMobileStyle.style_button(end_run_button, "red", 21)

	_update_layout_margins()
	call_deferred("_update_layout_margins")


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and _layout_built:
		_update_layout_margins()


func _add_stat_chip(id: String) -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(110, 66)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", SlayMobileStyle.panel_style(Color(0.015, 0.019, 0.018, 0.62), Color(0.42, 0.36, 0.22, 0.90), 7))
	_stats_grid.add_child(panel)

	var label := Label.new()
	SlayMobileStyle.style_label(label, 17, SlayMobileStyle.TEXT_MAIN, HORIZONTAL_ALIGNMENT_CENTER)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	panel.add_child(label)
	_stat_labels[id] = label


func _update_layout_margins() -> void:
	if not is_instance_valid(_summary_margin):
		return
	var horizontal_margin := clampf(size.x * 0.15, 18.0, 260.0)
	var vertical_margin := clampf(size.y * 0.10, 18.0, 72.0)
	if size.x < 720.0:
		horizontal_margin = 16.0
	if size.y < 620.0:
		vertical_margin = 14.0
	_summary_margin.offset_left = horizontal_margin
	_summary_margin.offset_right = -horizontal_margin
	_summary_margin.offset_top = vertical_margin
	_summary_margin.offset_bottom = -vertical_margin
	if _stats_grid:
		_stats_grid.columns = 2 if size.x < 760.0 else 4
	if _button_grid:
		_button_grid.columns = 1 if size.x < 620.0 else 2


func _show_summary(run_end_state: int) -> void:
	player_run_end_state = run_end_state
	visible = true
	_refresh_summary_display()


func _refresh_summary_display() -> void:
	if not _layout_built:
		return
	victory_label.visible = false
	defeat_label.visible = false
	quit_label.visible = false
	prompt_label.visible = false

	var stats := Global.player_data.get_statistics_for_summary()
	var floor_reached := int(stats.get("floor_reached", 0))
	var cards_obtained := int(stats.get("cards_obtained", 0))
	var enemies_defeated := int(stats.get("enemies_defeated", 0))
	var words_reviewed := int(stats.get("words_reviewed", 0))
	var words_correct := int(stats.get("words_correct", 0))
	var death_reason := str(stats.get("death_reason", ""))

	var title_key := "overlay.summary_title_quit"
	var hint_key := "overlay.summary_hint_quit"
	var badge_key := "overlay.summary_badge_quit"
	var mark_text := "离"
	var mark_color := SlayMobileStyle.TEXT_MAIN
	if player_run_end_state == Global.RUN_ENDS.VICTORY:
		title_key = "overlay.summary_title_victory"
		hint_key = "overlay.summary_hint_victory"
		badge_key = "overlay.summary_badge_victory"
		mark_text = "胜"
		mark_color = Color(0.76, 0.95, 0.62, 1.0)
	elif player_run_end_state == Global.RUN_ENDS.LOSS:
		title_key = "overlay.summary_title_defeat"
		hint_key = "overlay.summary_hint_defeat"
		badge_key = "overlay.summary_badge_defeat"
		mark_text = "败"
		mark_color = Color(1.0, 0.52, 0.48, 1.0)

	_result_mark_label.text = mark_text
	_result_mark_label.add_theme_color_override("font_color", mark_color)
	_status_label.text = I18N.tr_key(badge_key)
	_title_label.text = I18N.tr_key(title_key)
	_title_label.add_theme_color_override("font_color", mark_color)
	_hint_label.text = I18N.tr_key(hint_key)

	_set_stat_text("floor", I18N.tr_key("overlay.summary_stat_floor", [floor_reached]))
	_set_stat_text("enemies", I18N.tr_key("overlay.summary_stat_enemies", [enemies_defeated]))
	_set_stat_text("cards", I18N.tr_key("overlay.summary_stat_cards", [cards_obtained]))
	_set_stat_text("vocab", I18N.tr_key("overlay.summary_stat_vocab", [words_correct, words_reviewed]))

	_death_reason_label.visible = player_run_end_state == Global.RUN_ENDS.LOSS and not death_reason.strip_edges().is_empty()
	if _death_reason_label.visible:
		_death_reason_label.text = I18N.tr_key("run.stats.death_reason", [death_reason])

	view_statistics_button.text = I18N.tr_key("overlay.view_run_report")
	end_run_button.text = I18N.tr_key("overlay.back_to_main_menu")


func _set_stat_text(id: String, text: String) -> void:
	var label := _stat_labels.get(id) as Label
	if is_instance_valid(label):
		label.text = text


func _on_locale_changed(_locale: String) -> void:
	_refresh_summary_display()
