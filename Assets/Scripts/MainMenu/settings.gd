extends Control

@export var music_slider: HSlider
@export var fullscreen_checkbox: CheckBox
@export var close_button: Button

var music_player: AudioStreamPlayer

func _ready() -> void:
	# Проверяем узлы из инспектора
	if not music_slider:
		print("Error: music_slider not assigned in inspector")
	if not fullscreen_checkbox:
		print("Error: fullscreen_checkbox not assigned in inspector")
	if not close_button:
		print("Error: close_button not assigned in inspector")
	
	# Получаем AudioManager из Autoload
	if Engine.has_singleton("AudioManager"):
		music_player = Engine.get_singleton("AudioManager")
		if music_player:
			print("music_player set to AudioManager: ", music_player)
		else:
			print("Error: AudioManager is not an AudioStreamPlayer")
	else:
		print("Error: AudioManager singleton not found in Autoload")

	# Загрузка настроек
	var config = ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		var volume = config.get_value("audio", "music_volume", 0.0)
		var fullscreen = config.get_value("display", "fullscreen", false)
		
		if music_player and music_slider:
			music_player.volume_db = volume
			music_slider.value = volume
			print("Loaded volume: ", volume)
		
		if fullscreen:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		if fullscreen_checkbox:
			fullscreen_checkbox.set_pressed(fullscreen)
	else:
		if music_player and music_slider:
			music_slider.value = music_player.volume_db
			print("Default volume: ", music_player.volume_db)
		if fullscreen_checkbox:
			fullscreen_checkbox.set_pressed(DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)

	# Подключение сигналов
	if music_slider:
		music_slider.value_changed.connect(_on_music_slider_changed)
	else:
		print("Error: Cannot connect music_slider signal")
	if fullscreen_checkbox:
		fullscreen_checkbox.toggled.connect(_on_fullscreen_toggled)
	if close_button:
		close_button.pressed.connect(_on_close_pressed)

func _on_music_slider_changed(value: float) -> void:
	if music_player:
		music_player.volume_db = value
		print("Slider changed, new volume_db: ", value)
		var config = ConfigFile.new()
		config.set_value("audio", "music_volume", value)
		config.save("user://settings.cfg")
	else:
		print("Error: music_player is null, cannot change volume")

func _on_fullscreen_toggled(pressed: bool) -> void:
	if pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	var config = ConfigFile.new()
	config.set_value("display", "fullscreen", pressed)
	config.save("user://settings.cfg")

func _on_close_pressed() -> void:
	var scene_path = "res://Assets/Scene/main_menu.tscn"
	if ResourceLoader.exists(scene_path):
		get_tree().change_scene_to_file(scene_path)
	else:
		print("Error: Scene not found: ", scene_path)
