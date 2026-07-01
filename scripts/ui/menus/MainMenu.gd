# Main menu on title screen
extends Control

@onready var title_screen: Control = $%TitleScreen

@onready var continue_button: Button = $VBoxContainer/ContinueButton
@onready var forfeit_run_button: Button = $VBoxContainer/ForfeitRunButton
@onready var new_run_button: Button = $VBoxContainer/NewRunButton
@onready var codex_button: Button = $VBoxContainer/CodexButton
@onready var vocab_prefs_button: Button = $VBoxContainer/VocabPrefsButton
@onready var game_guide_button: Button = $VBoxContainer/GameGuideButton
@onready var language_button: Button = $VBoxContainer/SettingsButton
@onready var exit_button: Button = $VBoxContainer/ExitButton

# Test battle button
@onready var test_battle_button: Button = $VBoxContainer/TestBattleButton

func _ready():
	for b in [
		continue_button,
		forfeit_run_button,
		new_run_button,
		codex_button,
		vocab_prefs_button,
		game_guide_button,
		language_button,
		exit_button,
		test_battle_button,
	]:
		for legacy in b.get_children():
			if legacy.name == "LocalizedTextLabel":
				legacy.queue_free()
		b.alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.add_theme_font_size_override("font_size", 20)
		b.add_theme_color_override("font_color", Color(0.96, 0.93, 0.82, 1.0))
		b.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.65))
		b.add_theme_constant_override("outline_size", 1)
	
	# Set test battle button text directly
	test_battle_button.text = I18N.tr_key("menu.test_battle")

	continue_button.pressed.connect(_on_continue_button_up)
	forfeit_run_button.pressed.connect(_on_forfeit_run_button_up)
	new_run_button.pressed.connect(_on_new_run_button_up)
	codex_button.pressed.connect(_on_codex_button_up)
	vocab_prefs_button.pressed.connect(_on_vocab_prefs_button_up)
	game_guide_button.pressed.connect(_on_game_guide_button_up)
	language_button.pressed.connect(_on_language_button_up)
	exit_button.pressed.connect(_on_exit_button_up)
	test_battle_button.pressed.connect(_on_test_battle_button_up)

	Signals.run_ended.connect(_on_run_ended)
	I18N.locale_changed.connect(_on_locale_changed)

	language_button.disabled = false
	update_continue_button_visibility()
	_update_language_button()

func _on_continue_button_up():
	FileLoader.autoload()

func _on_forfeit_run_button_up():
	FileLoader.delete_save()
	update_continue_button_visibility()

func _on_new_run_button_up():
	title_screen.show_new_run_menu()

func _on_codex_button_up():
	title_screen.show_codex_menu()

func _on_vocab_prefs_button_up():
	title_screen.show_vocab_prefs_menu()

func _on_game_guide_button_up():
	title_screen.show_game_guide_menu()

func _on_language_button_up():
	I18N.toggle_locale()

func _on_exit_button_up():
	get_tree().quit()

func _on_test_battle_button_up():
	title_screen.show_test_combat_menu()

func update_continue_button_visibility() -> void:
	var has_save_file: bool = FileLoader.has_save_file()
	continue_button.visible = has_save_file
	forfeit_run_button.visible = has_save_file
	new_run_button.visible = not has_save_file

func _on_run_ended():
	update_continue_button_visibility()

func _on_locale_changed(_locale: String) -> void:
	_update_language_button()

func _update_language_button() -> void:
	if I18N.current_locale == "zh_CN":
		language_button.tooltip_text = I18N.tr_key("menu.language_switch_to_en")
	else:
		language_button.tooltip_text = I18N.tr_key("menu.language_switch_to_zh")
