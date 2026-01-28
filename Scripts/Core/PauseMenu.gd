extends CanvasLayer

@export_category("Buttons")
@export var continue_button: Button
@export var settings_button: Button
@export var quit_button: Button

@export_category("Panels")
@export var control_panel: Control

const MAIN_MENU_PATH := "res://Scene/MainMenu/MainMenu.tscn"

var menu_open: bool = false
var _hover_sound: AudioStreamPlayer = null
var _main_buttons: Array[Button] = []

func _ready() -> void:
	visible = false
	
	if control_panel:
		control_panel.visible = false
	
	_cache_references()
	_setup_buttons()

func _cache_references() -> void:
	var sound_nodes := get_tree().get_nodes_in_group("Sound")
	for node in sound_nodes:
		if node.name == "Button" and node is AudioStreamPlayer:
			_hover_sound = node
			break

func _setup_buttons() -> void:
	_main_buttons = [continue_button, settings_button, quit_button]
	
	if continue_button:
		continue_button.pressed.connect(_on_continue_pressed)
		continue_button.mouse_entered.connect(_on_button_hover)
	
	if settings_button:
		settings_button.pressed.connect(_on_settings_pressed)
		settings_button.mouse_entered.connect(_on_button_hover)
	
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)
		quit_button.mouse_entered.connect(_on_button_hover)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_toggle_menu()

func _toggle_menu() -> void:
	menu_open = not menu_open
	visible = menu_open
	
	var mouse_mode := Input.MOUSE_MODE_VISIBLE if menu_open else Input.MOUSE_MODE_CAPTURED
	Input.set_mouse_mode(mouse_mode)
	
	get_tree().paused = menu_open
	
	if menu_open and control_panel:
		_show_main_buttons()

func _show_main_buttons() -> void:
	if control_panel:
		control_panel.visible = false
	
	for button in _main_buttons:
		if button:
			button.visible = true

func _show_settings() -> void:
	if control_panel:
		control_panel.visible = true
	
	for button in _main_buttons:
		if button:
			button.visible = false

func _on_continue_pressed() -> void:
	_toggle_menu()

func _on_settings_pressed() -> void:
	_show_settings()

func _on_quit_pressed() -> void:
	_save_and_quit()

func _on_button_hover() -> void:
	if _hover_sound:
		if _hover_sound.playing:
			_hover_sound.stop()
		_hover_sound.play()

func _save_and_quit() -> void:
	_save_current_scene()
	_get_player()
	
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU_PATH)

func _get_player() -> void:
	var player = get_tree().get_nodes_in_group("Player")[0]
	if player and player.has_method("save_position"):
		player.save_position()

func _save_current_scene() -> void:
	if get_tree().current_scene:
		var packed_scene = PackedScene.new()
		if packed_scene.pack(get_tree().current_scene) == OK:
			SaveManager.loaded_scene_data = packed_scene

func close_settings() -> void:
	_show_main_buttons()

func open_menu() -> void:
	if not menu_open:
		_toggle_menu()

func close_menu() -> void:
	if menu_open:
		_toggle_menu()
