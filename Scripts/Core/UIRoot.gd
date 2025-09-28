extends CanvasLayer

@export var continue_button: Button
@export var settings_button: Button
@export var quit_button: Button
@export var control_panel: Control
@export var player_node: Node3D

var menu_open := false
var initial_restore_done := false

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
	var player_with_script = _find_player_with_script()
	if player_with_script and not initial_restore_done:
		if not GameState.loaded_player_data.is_empty():
			player_with_script.position = GameState.loaded_player_data.get("position", player_with_script.position)
			player_with_script.rotation.y = GameState.loaded_player_data.get("rotation_y", player_with_script.rotation.y)
			initial_restore_done = true
		GameState.clear_loaded_data()

func _process(_delta):
	var player_with_script = _find_player_with_script()
	if player_with_script and initial_restore_done:
		var expected_position = GameState.loaded_player_data.get("position", Vector3.ZERO)
		var expected_rotation = GameState.loaded_player_data.get("rotation_y", player_with_script.rotation.y)
		player_with_script.position = expected_position
		player_with_script.rotation.y = expected_rotation

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		menu_open = !menu_open
		visible = menu_open
		if menu_open:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			get_tree().paused = true
		else:
			get_tree().paused = false
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_continue_pressed() -> void:
	visible = false
	menu_open = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	get_tree().paused = false

func _on_settings_pressed() -> void:
	control_panel.visible = true
	continue_button.visible = false
	settings_button.visible = false
	quit_button.visible = false

func _on_button_hover() -> void:
	if AudioManager.has_node("ButtonPlayer"):
		var player = AudioManager.get_node("ButtonPlayer") as AudioStreamPlayer
		if player.playing:
			player.stop()
		player.play()

func _on_quit_pressed() -> void:
	var player_with_script = _find_player_with_script()
	if player_with_script and player_with_script.has_method("save_position"):
		player_with_script.save_position()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scene/main_menu.tscn")

func _find_player_with_script() -> Node:
	if not player_node:
		return null
	var player_with_script = player_node.find_child("*", true, false) as Node
	while player_with_script:
		if player_with_script.get_script() == load("res://Scripts/Map/Movement.gd"):
			return player_with_script
		player_with_script = player_with_script.find_child("*", true, false) as Node
	return null
