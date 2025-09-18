extends CanvasLayer

@export var start_button: Button
@export var settings_button: Button
@export var quit_button: Button

@export_file("*.tscn") var start_scene: String
@export_file("*.tscn") var settings_scene: String

func _ready() -> void:
	if start_button:
		start_button.pressed.connect(_on_start_pressed)
	if settings_button:
		settings_button.pressed.connect(_on_settings_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)

func _on_start_pressed() -> void:
	if start_scene != "":
		if has_node("/root/AsteroidManager"):
			get_node("/root/AsteroidManager").queue_free()
		get_tree().change_scene_to_file(start_scene)
	else:
		push_warning("Не выбрана сцена для кнопки 'Начать игру'!")

func _on_settings_pressed() -> void:
	if settings_scene != "":
		get_tree().change_scene_to_file(settings_scene)
	else:
		push_warning("Не выбрана сцена для кнопки 'Настройки'!")

func _on_quit_pressed() -> void:
	get_tree().quit()
