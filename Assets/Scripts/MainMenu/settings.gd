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

	# Загрузка сохранённых настроек
	load_settings()

func _on_music_slider_changed(value: float) -> void:
	music_player.volume_db = value

func _on_fullscreen_toggled(pressed: bool) -> void:
	if pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)

func _on_close_pressed() -> void:
	# Сохранить настройки
	save_settings()
	
	# Скрыть панель
	visible = false
	
	# Получить доступ к кнопкам через CanvasLayer
	var canvas_layer = get_parent()
	if canvas_layer:
		var start_button = canvas_layer.get_node("Start")
		var settings_button = canvas_layer.get_node("Settings")
		var exit_button = canvas_layer.get_node("Exit")
		
		# Проверка наличия нод перед изменением visible
		if start_button:
			start_button.visible = true
		if settings_button:
			settings_button.visible = true
		if exit_button:
			exit_button.visible = true

func save_settings():
	var config = ConfigFile.new()
	config.set_value("Settings", "volume_db", music_slider.value)
	config.set_value("Settings", "fullscreen", fullscreen_checkbox.button_pressed)
	config.save("user://settings.cfg")

func load_settings():
	var config = ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		music_slider.value = config.get_value("Settings", "volume_db", 0.0)
		fullscreen_checkbox.button_pressed = config.get_value("Settings", "fullscreen", false)
		_on_music_slider_changed(music_slider.value)
		_on_fullscreen_toggled(fullscreen_checkbox.button_pressed)
