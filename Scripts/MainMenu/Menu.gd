extends CanvasLayer

@export var start_button: Button
@export var load_button: Button
@export var settings_button: Button
@export var quit_button: Button
@export var control_panel: Control
@export_file("*.tscn") var start_scene: String

const SAVE_PATH := "user://game_save.tres"

func _ready() -> void:
	control_panel.visible = false

	var buttons := [start_button, load_button, settings_button, quit_button]
	for button in buttons:
		button.pressed.connect(_on_button_pressed(button))
		button.mouse_entered.connect(_on_button_hover)

	load_button.disabled = not ResourceLoader.exists(SAVE_PATH)

func _on_button_pressed(button: Button) -> Callable:
	return Callable(self, "_handle_button_pressed").bind(button)

func _handle_button_pressed(button: Button) -> void:
	match button:
		start_button: _on_start_pressed()
		load_button: _handle_load()
		settings_button: _handle_settings()
		quit_button: _handle_quit()

func _on_start_pressed() -> void:
	if ResourceLoader.exists(SAVE_PATH):
		var dialog := ConfirmationDialog.new()
		dialog.dialog_text = "У вас есть сохранение. Вы уверены, что хотите начать новую игру? Это перезапишет текущее сохранение."
		dialog.confirmed.connect(_start_new_game)
		add_child(dialog)
		dialog.popup_centered()
	else:
		_start_new_game()

func _start_new_game() -> void:
	if start_scene == "": return
	if ResourceLoader.exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	GameState.clear_loaded_data()
	get_tree().change_scene_to_file(start_scene)

func _handle_load() -> void:
	if not ResourceLoader.exists(SAVE_PATH):
		return
	var save_data := ResourceLoader.load(SAVE_PATH) as GameSave
	if save_data and save_data.scene_data:
		GameState.loaded_player_data = save_data.player_data
		GameState.loaded_scene_data = save_data.scene_data
		get_tree().change_scene_to_packed(GameState.loaded_scene_data)

func _handle_settings() -> void:
	control_panel.visible = true
	start_button.visible = false
	load_button.visible = false
	settings_button.visible = false
	quit_button.visible = false

func _handle_quit() -> void:
	get_tree().quit()

func _on_button_hover() -> void:
	var players := get_tree().get_nodes_in_group("Sound")
	for player in players:
		if player.name == "Button" and player is AudioStreamPlayer:
			if player.playing:
				player.stop()
			player.play()
			break
