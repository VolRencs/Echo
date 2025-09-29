extends CanvasLayer

@export var continue_button: Button
@export var settings_button: Button
@export var quit_button: Button
@export var control_panel: Control
@export var player_node: Node3D

var menu_open := false

func _ready() -> void:
	visible = false
	control_panel.visible = false
	
	continue_button.pressed.connect(_on_continue_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	continue_button.mouse_entered.connect(_on_button_hover)
	settings_button.mouse_entered.connect(_on_button_hover)
	quit_button.mouse_entered.connect(_on_button_hover)

	_restore_player_position()

func _restore_player_position():
	var player = _find_player()
	if player:
		player.position = GameState.loaded_player_data.get("position", player.position)
		player.rotation.y = GameState.loaded_player_data.get("rotation_y", player.rotation.y)
		GameState.clear_loaded_data()

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		menu_open = !menu_open
		visible = menu_open
		if menu_open:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			get_tree().paused = true
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			get_tree().paused = false

func _on_continue_pressed() -> void:
	menu_open = false
	visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	get_tree().paused = false

func _on_settings_pressed() -> void:
	control_panel.visible = true
	continue_button.visible = false
	settings_button.visible = false
	quit_button.visible = false

func _on_button_hover() -> void:
	var players = get_tree().get_nodes_in_group("Sound")
	for player in players:
		if player.name == "Button" and player is AudioStreamPlayer:
			if player.playing:
				player.stop()
			player.play()
			break

func _on_quit_pressed() -> void:
	var player = _find_player()
	if player and player.has_method("save_position"):
		player.save_position()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scene/main_menu.tscn")

func _find_player() -> Node:
	if not player_node:
		return null
	for child in player_node.get_children():
		if child.get_script() == load("res://Scripts/Map/Movement.gd"):
			return child
	return null
