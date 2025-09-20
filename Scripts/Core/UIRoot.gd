extends CanvasLayer

@export var continue_button: Button
@export var settings_button: Button
@export var quit_button: Button
@export var control_panel: Control

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

	_set_pause_mode_recursive(self, 2) # 2 = PROCESS

func _set_pause_mode_recursive(node: Node, mode: int) -> void:
	if "pause_mode" in node:
		node.pause_mode = mode
	for child in node.get_children():
		_set_pause_mode_recursive(child, mode)

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		menu_open = !menu_open
		visible = menu_open
		if menu_open:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			get_tree().paused = true # пауза игры, CanvasLayer продолжает работать
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
	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scene/main_menu.tscn")
