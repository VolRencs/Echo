extends CanvasLayer

@export var start_button: Button
@export var settings_button: Button
@export var quit_button: Button

@export_file("*.tscn") var start_scene: String
@export var settings_scene: PackedScene

func _ready() -> void:
	if start_button:
		start_button.pressed.connect(_on_start_pressed)
	if settings_button:
		settings_button.pressed.connect(_on_settings_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)

func _on_start_pressed() -> void:
	if start_scene != "":
		get_tree().change_scene_to_file(start_scene)
	else:
		push_warning("Не выбрана сцена для кнопки 'Начать игру'!")

func _on_settings_pressed() -> void:
	if settings_scene:
		var settings = settings_scene.instantiate()
		get_tree().current_scene.add_child(settings)
	else:
		push_warning("Не назначена сцена настроек!")

func _on_quit_pressed() -> void:
	get_tree().quit()
