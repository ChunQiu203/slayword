# title screen of game
# composed of sub menus with their own logic
# does nothing except control sub menu display logic
extends Control

@onready var main_menu = $MainMenu
@onready var new_run_menu = $NewRunMenu
@onready var codex_menu = $CodexMenu
@onready var vocab_prefs_menu = $VocabPrefsMenu
@onready var game_guide_menu = $GameGuideMenu
@onready var test_combat_menu = $TestCombatMenu
@onready var test_event_menu = $TestEventMenu

func _ready():
	Signals.run_started.connect(_on_run_started)
	Signals.run_ended.connect(_on_run_ended)

func hide_menus():
	main_menu.visible = false
	new_run_menu.visible = false
	codex_menu.visible = false
	vocab_prefs_menu.visible = false
	game_guide_menu.visible = false
	test_combat_menu.visible = false
	test_event_menu.visible = false

func show_main_menu():
	hide_menus()
	main_menu.visible = true

func show_new_run_menu():
	hide_menus()
	new_run_menu.visible = true
	new_run_menu.populate_new_run_menu()

func show_codex_menu():
	hide_menus()
	codex_menu.visible = true
	codex_menu.populate_codex_menu()

func show_vocab_prefs_menu():
	hide_menus()
	vocab_prefs_menu.visible = true
	vocab_prefs_menu.populate_vocab_prefs_menu()

func show_game_guide_menu():
	hide_menus()
	game_guide_menu.visible = true

func show_test_combat_menu():
	hide_menus()
	test_combat_menu.visible = true
	test_combat_menu.populate_test_menu()

func show_test_event_menu():
	hide_menus()
	test_event_menu.visible = true
	test_event_menu.populate_test_menu()

func _on_run_started():
	visible = false

func _on_run_ended():
	visible = true
	show_main_menu()
