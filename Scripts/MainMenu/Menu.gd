extends CanvasLayer

@export var start_button: Button
@export var load_button: Button
@export var settings_button: Button
@export var quit_button: Button
@export var control_panel: Control
var start_scene: String = "res://Scene/Core/Game.tscn"

func _ready() -> void:
	SaveManager.load_game()
	control_panel.visible = false

	var buttons := [start_button, load_button, settings_button, quit_button]
	for button in buttons:
		button.pressed.connect(_on_button_pressed(button))
		button.mouse_entered.connect(_on_button_hover)

	load_button.disabled = SaveManager.loaded_player_data.is_empty()

func _on_button_pressed(button: Button) -> Callable:
	return Callable(self, "_handle_button_pressed").bind(button)

func _handle_button_pressed(button: Button) -> void:
	match button:
		start_button: _on_start_pressed()
		load_button: _handle_load()
		settings_button: _handle_settings()
		quit_button: _handle_quit()

func _on_start_pressed() -> void:
	if not SaveManager.loaded_player_data.is_empty():
		var dialog := ConfirmationDialog.new()
		dialog.set_title("Подтверждение")
		dialog.set_text("Сохранение найдено. Начать новую игру и перезаписать его?")
		add_child(dialog)
		dialog.confirmed.connect(_start_new_game)
		dialog.popup_centered()
	else:
		_start_new_game()

func _start_new_game() -> void:
	SaveManager.clear_loaded_data()
	SaveManager.delete_save()
	get_tree().change_scene_to_file(start_scene)

func _handle_load() -> void:
	if SaveManager.loaded_player_data.is_empty():
		return
	if SaveManager.loaded_scene_data:
		get_tree().change_scene_to_packed(SaveManager.loaded_scene_data)

func _handle_settings() -> void:
	control_panel.visible = true
	start_button.visible = false
	load_button.visible = false
	settings_button.visible = false
	quit_button.visible = false

func _handle_quit() -> void:
	get_tree().quit()

func _on_button_hover() -> void:
	for node in get_tree().get_nodes_in_group("Sound"):
		if node is AudioStreamPlayer and node.name == "Button":
			node.stop()
			node.play()
			break
