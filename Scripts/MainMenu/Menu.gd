extends CanvasLayer

@export var start_button: Button
@export var load_button: Button
@export var settings_button: Button
@export var quit_button: Button
@export var control_panel: Control
@export_file("*.tscn") var start_scene: String

const SAVE_PATH = "user://game_save.tres"

func _ready() -> void:
	control_panel.visible = false
	
	start_button.pressed.connect(_on_start_pressed)
	load_button.pressed.connect(_on_load_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	start_button.mouse_entered.connect(_on_button_hover)
	load_button.mouse_entered.connect(_on_button_hover)
	settings_button.mouse_entered.connect(_on_button_hover)
	quit_button.mouse_entered.connect(_on_button_hover)
	
	load_button.disabled = not ResourceLoader.exists(SAVE_PATH)

func _on_start_pressed() -> void:
	if ResourceLoader.exists(SAVE_PATH):
		var dialog = ConfirmationDialog.new()
		dialog.dialog_text = "У вас есть сохранение. Вы уверены, что хотите начать новую игру? Это перезапишет текущее сохранение."
		dialog.confirmed.connect(_start_new_game)
		dialog.canceled.connect(dialog.queue_free)
		add_child(dialog)
		dialog.popup_centered()
	else:
		_start_new_game()

func _start_new_game() -> void:
	if start_scene != "":
		if ResourceLoader.exists(SAVE_PATH):
			DirAccess.remove_absolute(SAVE_PATH)
		GameState.clear_loaded_data()
		get_tree().change_scene_to_file(start_scene)

func _on_load_pressed() -> void:
	if ResourceLoader.exists(SAVE_PATH):
		var save_data = ResourceLoader.load(SAVE_PATH) as GameSave
		if save_data and save_data.scene_data:
			GameState.loaded_player_data = save_data.player_data
			GameState.loaded_scene_data = save_data.scene_data
			get_tree().change_scene_to_packed(GameState.loaded_scene_data)

func _on_button_hover() -> void:
	if AudioManager.has_node("ButtonPlayer"):
		var player = AudioManager.get_node("ButtonPlayer") as AudioStreamPlayer
		if player.playing:
			player.stop()
		player.play()

func _on_settings_pressed() -> void:
	control_panel.visible = true
	start_button.visible = false
	load_button.visible = false
	settings_button.visible = false
	quit_button.visible = false

func _on_quit_pressed() -> void:
	get_tree().quit()
