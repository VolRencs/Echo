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
	var player = get_tree().get_nodes_in_group("Player")[0]
	if player and player.has_method("save_position"):
		player.save_position()
	if get_tree().current_scene:
		var packed_scene = PackedScene.new()
		if packed_scene.pack(get_tree().current_scene) == OK:
			SaveManager.loaded_scene_data = packed_scene

	get_tree().paused = false
	get_tree().change_scene_to_file("res://Scene/MainMenu/MainMenu.tscn")
