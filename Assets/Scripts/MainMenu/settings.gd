extends Control

@export var music_slider: HSlider
@export var fullscreen_checkbox: CheckBox
@export var close_button: Button

var music_player: AudioStreamPlayer

func _ready() -> void:
	# Берём AudioStreamPlayer из автозагруза AudioManager
	music_player = get_node("/root/AudioManager/AudioStreamPlayer") as AudioStreamPlayer

	# Настройка диапазона слайдера под volume_db
	music_slider.min_value = -40
	music_slider.max_value = 0

	# Инициализация значений из текущего состояния
	music_slider.value = music_player.volume_db
	fullscreen_checkbox.button_pressed = (DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)

	# Подключение сигналов
	music_slider.value_changed.connect(_on_music_slider_changed)
	fullscreen_checkbox.toggled.connect(_on_fullscreen_toggled)
	close_button.pressed.connect(_on_close_pressed)

func _on_music_slider_changed(value: float) -> void:
	music_player.volume_db = value

func _on_fullscreen_toggled(pressed: bool) -> void:
	if pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_close_pressed() -> void:
	get_tree().change_scene_to_file("res://Assets/Scene/main_menu.tscn")
