extends CanvasLayer

@export var start_button: Button
@export var settings_button: Button
@export var quit_button: Button
@export var control_panel: Control
@export_file("*.tscn") var start_scene: String

func _ready() -> void:
	# Скрыть панель настроек по умолчанию
	control_panel.visible = false
	
	# Настройка кнопок главного меню
	start_button.pressed.connect(_on_start_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

func _on_start_pressed() -> void:
	if start_scene != "":
		if has_node("/root/AsteroidManager"):
			get_node("/root/AsteroidManager").queue_free()
		get_tree().change_scene_to_file(start_scene)
	else:
		push_warning("Не выбрана сцена для кнопки 'Начать игру'!")

func _on_settings_pressed() -> void:
	# Показать панель настроек
	control_panel.visible = true
	# Скрыть кнопки главного меню
	start_button.visible = false
	settings_button.visible = false
	quit_button.visible = false

func _on_quit_pressed() -> void:
	get_tree().quit()
