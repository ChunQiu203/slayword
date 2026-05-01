extends Control

const TEXTURE_BUTTON_LABEL_NAME := "LocalizedTextLabel"

@onready var resume_button: TextureButton = %ResumeButton
@onready var return_to_title_button: TextureButton = %ReturnToTitleButton
@onready var forfeit_run_button: TextureButton = %ForfeitRunButton

func _ready() -> void:
	_apply_localized_text()
	I18N.locale_changed.connect(_on_locale_changed)

	resume_button.pressed.connect(_on_resume_button_pressed)
	return_to_title_button.pressed.connect(_on_return_to_title_button_pressed)
	forfeit_run_button.pressed.connect(_on_forfeit_run_button_pressed)
	
	Signals.run_started.connect(_on_run_started)
	Signals.run_ended.connect(_on_run_ended)
	
	Signals.game_paused.connect(_on_game_paused)
	Signals.game_unpaused.connect(_on_game_unpaused)

func _on_locale_changed(_locale: String) -> void:
	_apply_localized_text()

func _apply_localized_text() -> void:
	_set_texture_button_label(resume_button, I18N.tr_key("overlay.resume"))
	_set_texture_button_label(return_to_title_button, I18N.tr_key("overlay.return_to_title"))
	_set_texture_button_label(forfeit_run_button, I18N.tr_key("menu.forfeit_run"))

func _set_texture_button_label(button: TextureButton, localized_text: String) -> void:
	var label := button.get_node_or_null(TEXTURE_BUTTON_LABEL_NAME) as Label
	if label == null:
		label = Label.new()
		label.name = TEXTURE_BUTTON_LABEL_NAME
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.clip_text = true
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_WORD_ELLIPSIS
		button.add_child(label)
		label.set_anchors_preset(Control.PRESET_FULL_RECT)
		label.offset_left = 0.0
		label.offset_top = 0.0
		label.offset_right = 0.0
		label.offset_bottom = 0.0

	label.text = localized_text
	_resize_texture_button_label(button, label)
	call_deferred("_resize_texture_button_label", button, label)
	label.add_theme_font_size_override("font_size", _get_texture_button_font_size(localized_text))
	label.add_theme_color_override("font_color", Color(0.96, 0.93, 0.82, 1.0))
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.0))
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", 0)
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.65))
	label.add_theme_constant_override("outline_size", 1)

func _resize_texture_button_label(button: TextureButton, label: Label) -> void:
	if not is_instance_valid(button) or not is_instance_valid(label):
		return
	label.position = Vector2.ZERO
	label.size = button.size

func _get_texture_button_font_size(localized_text: String) -> int:
	if localized_text.length() >= 13:
		return 17
	if localized_text.length() >= 9:
		return 19
	return 21

func _on_run_started():
	visible = false
	
func _on_run_ended():
	visible = false
	

func _on_resume_button_pressed() -> void:
	Global.unpause_game()

func _on_return_to_title_button_pressed() -> void:
	Global.unpause_game()
	Global.end_run(Global.RUN_ENDS.QUIT)

func _on_forfeit_run_button_pressed() -> void:
	Global.unpause_game()
	Global.end_run(Global.RUN_ENDS.LOSS)

func _on_game_paused() -> void:
	visible = true
	_apply_localized_text()

func _on_game_unpaused() -> void:
	visible = false
