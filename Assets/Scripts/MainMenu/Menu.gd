extends CanvasLayer

@export var start_button: Button
@export var settings_button: Button
@export var quit_button: Button
@export var control_panel: Control
@export_file("*.tscn") var start_scene: String

func _ready() -> void:
	control_panel.visible = false
	
	start_button.pressed.connect(_on_start_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	start_button.mouse_entered.connect(_on_button_hover)
	settings_button.mouse_entered.connect(_on_button_hover)
	quit_button.mouse_entered.connect(_on_button_hover)


func _on_start_pressed() -> void:
	if start_scene != "":
		if has_node("/root/AsteroidManager"):
			get_node("/root/AsteroidManager").queue_free()
		get_tree().change_scene_to_file(start_scene)
		
func _on_button_hover() -> void:
	if AudioManager.has_node("ButtonPlayer"):
		var player = AudioManager.get_node("ButtonPlayer") as AudioStreamPlayer
		if player.playing:
			player.stop()
		player.play()

func _on_settings_pressed() -> void:
	control_panel.visible = true

	start_button.visible = false
	settings_button.visible = false
	quit_button.visible = false

func _on_quit_pressed() -> void:
	get_tree().quit()
