extends CanvasLayer

@export_category("Buttons")
@export var start_button: Button
@export var load_button: Button
@export var settings_button: Button
@export var quit_button: Button

@export_category("Panels")
@export var control_panel: Control

@export_category("Scenes")
@export var start_scene: String = "res://Scene/Core/Game.tscn"

var _hover_sound: AudioStreamPlayer = null
var _main_buttons: Array[Button] = []

func _ready() -> void:
	SaveManager.load_game()
	
	_setup_ui()
	
	_cache_hover_sound()
	
	_setup_buttons()
	
	_update_load_button()

func _setup_ui() -> void:
	if control_panel:
		control_panel.visible = false

func _cache_hover_sound() -> void:
	var sound_nodes := get_tree().get_nodes_in_group("Sound")
	for node in sound_nodes:
		if node.name == "Button" and node is AudioStreamPlayer:
			_hover_sound = node
			return

func _setup_buttons() -> void:
	_main_buttons = [start_button, load_button, settings_button, quit_button]
	
	if start_button:
		start_button.pressed.connect(_on_start_pressed)
		start_button.mouse_entered.connect(_on_button_hover)
	
	if load_button:
		load_button.pressed.connect(_on_load_pressed)
		load_button.mouse_entered.connect(_on_button_hover)
	
	if settings_button:
		settings_button.pressed.connect(_on_settings_pressed)
		settings_button.mouse_entered.connect(_on_button_hover)
	
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)
		quit_button.mouse_entered.connect(_on_button_hover)

func _update_load_button() -> void:
	load_button.disabled = SaveManager.loaded_player_data.is_empty()

func _on_start_pressed() -> void:
	if SaveManager.has_save():
		_show_overwrite_dialog()
	else:
		_start_new_game()

func _on_load_pressed() -> void:
	if SaveManager.loaded_player_data.is_empty():
		return
	if SaveManager.loaded_scene_data:
		get_tree().change_scene_to_packed(SaveManager.loaded_scene_data)

func _on_settings_pressed() -> void:
	_toggle_settings(true)

func _on_quit_pressed() -> void:
	get_tree().quit()

func _show_overwrite_dialog() -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = "Подтверждение"
	dialog.dialog_text = "Сохранение найдено. Начать новую игру и перезаписать его?"
	
	add_child(dialog)
	dialog.confirmed.connect(_start_new_game)
	dialog.close_requested.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)
	
	dialog.popup_centered()

func _start_new_game() -> void:
	SaveManager.clear_loaded_data()
	if SaveManager.has_save():
		SaveManager.delete_save()
	get_tree().change_scene_to_file(start_scene)

func _toggle_settings(show_settings: bool) -> void:
	if control_panel:
		control_panel.visible = show_settings
	
	for button in _main_buttons:
		if button:
			button.visible = not show_settings

func _on_button_hover() -> void:
	if _hover_sound:
		_hover_sound.stop()
		_hover_sound.play()

func close_settings() -> void:
	_toggle_settings(false)

func refresh_load_button() -> void:
	_update_load_button()
