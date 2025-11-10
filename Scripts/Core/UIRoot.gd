extends CanvasLayer

@export var continue_button: Button
@export var settings_button: Button
@export var quit_button: Button
@export var control_panel: Control
@export var player_node: Node3D

var menu_open: bool = false

func _ready() -> void:
	visible = false
	control_panel.visible = false

	continue_button.pressed.connect(Callable(self, "_on_button_pressed").bind(continue_button))
	settings_button.pressed.connect(Callable(self, "_on_button_pressed").bind(settings_button))
	quit_button.pressed.connect(Callable(self, "_on_button_pressed").bind(quit_button))

	for button in [continue_button, settings_button, quit_button]:
		button.mouse_entered.connect(_on_button_hover)

	_restore_player_position()

func _restore_player_position() -> void:
	var player = _find_player()
	if player:
		player.position = GameState.loaded_player_data.get("position", player.position)
		player.rotation.y = GameState.loaded_player_data.get("rotation_y", player.rotation.y)
		GameState.clear_loaded_data()

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		_toggle_menu()

func _toggle_menu() -> void:
	menu_open = !menu_open
	visible = menu_open
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if menu_open else Input.MOUSE_MODE_CAPTURED)
	get_tree().paused = menu_open

func _on_button_pressed(sender: Button) -> void:
	match sender:
		continue_button:
			_toggle_menu()
		settings_button:
			_show_settings()
		quit_button:
			_quit_game()

func _show_settings() -> void:
	control_panel.visible = true
	for btn in [continue_button, settings_button, quit_button]:
		btn.visible = false

func _on_button_hover() -> void:
	for player in get_tree().get_nodes_in_group("Sound"):
		if player.name == "Button" and player is AudioStreamPlayer:
			if player.playing:
				player.stop()
			player.play()
			break

func _quit_game() -> void:
	var player = _find_player()
	if player and player.has_method("save_position"):
		player.save_position()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scene/MainMenu/MainMenu.tscn")

func _find_player() -> Node:
	if not player_node:
		return null
	for child in player_node.get_children():
		if child.get_script() == load("res://Scripts/Player/Player.gd"):
			return child
	return null
