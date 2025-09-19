extends Control

@export var music_slider: HSlider
@export var fullscreen_checkbox: CheckBox
@export var close_button: Button

var audio_players: Array[AudioStreamPlayer] = [] # Массив для всех AudioStreamPlayer

func _ready() -> void:
	var audio_manager = get_node("/root/AudioManager")
	if audio_manager:
		for child in audio_manager.get_children():
			if child is AudioStreamPlayer:
				audio_players.append(child)

	music_slider.min_value = -40
	music_slider.max_value = 0

	if not audio_players.is_empty() and audio_players[0]:
		music_slider.value = audio_players[0].volume_db

	fullscreen_checkbox.button_pressed = (DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)

	music_slider.value_changed.connect(_on_music_slider_changed)
	fullscreen_checkbox.toggled.connect(_on_fullscreen_toggled)
	close_button.pressed.connect(_on_close_pressed)
	
	close_button.mouse_entered.connect(_on_button_hover)
	
	load_settings()

func _on_music_slider_changed(value: float) -> void:
	for player in audio_players:
			if player:
				player.volume_db = value

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

func _on_button_hover() -> void:
	if AudioManager.has_node("ButtonPlayer"):
		var player = AudioManager.get_node("ButtonPlayer") as AudioStreamPlayer
		if player.playing:
			player.stop()
		player.play()

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
