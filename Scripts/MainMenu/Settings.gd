extends Control

@export var music_slider: HSlider
@export var sound_slider: HSlider
@export var fullscreen_checkbox: CheckBox
@export var vsync_checkbox: CheckBox
@export var refresh_rate_option: OptionButton
@export var close_button: Button

var refresh_rates: Array[float] = [60.0, 75.0, 100.0, 120.0, 144.0, 165.0, 180.0, 240.0]

func load_settings():
	var config := ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		music_slider.value = config.get_value("Settings", "volume_db", 0.0)
		sound_slider.value = config.get_value("Settings", "sound_volume_db", 0.0)
		fullscreen_checkbox.button_pressed = config.get_value("Settings", "fullscreen", false)
		vsync_checkbox.button_pressed = config.get_value("Settings", "vsync", true)
		var saved_rate: float = config.get_value("Settings", "refresh_rate", 60.0)
		var rate_index: int = refresh_rates.find(saved_rate)
		if rate_index >= 0:
			refresh_rate_option.select(rate_index)
			_on_refresh_rate_selected(rate_index)
		_on_music_slider_changed(music_slider.value)
		_on_sound_slider_changed(sound_slider.value)
		_on_fullscreen_toggled(fullscreen_checkbox.button_pressed)
		_on_vsync_toggled(vsync_checkbox.button_pressed)

func _ready() -> void:
	music_slider.min_value = -40
	music_slider.max_value = 0
	sound_slider.min_value = -40
	sound_slider.max_value = 0
	
	var music_players := get_tree().get_nodes_in_group("Music")
	var sound_players := get_tree().get_nodes_in_group("Sound")

	if music_players.size() > 0:
		music_slider.value = music_players[0].volume_db
	if sound_players.size() > 0:
		sound_slider.value = sound_players[0].volume_db

	fullscreen_checkbox.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN

	_populate_refresh_rates()

	music_slider.value_changed.connect(_on_music_slider_changed)
	sound_slider.value_changed.connect(_on_sound_slider_changed)
	fullscreen_checkbox.toggled.connect(_on_fullscreen_toggled)
	vsync_checkbox.toggled.connect(_on_vsync_toggled)
	refresh_rate_option.item_selected.connect(_on_refresh_rate_selected)
	close_button.pressed.connect(_on_close_pressed)
	close_button.mouse_entered.connect(_on_button_hover)

	load_settings()

func _populate_refresh_rates() -> void:
	refresh_rate_option.clear()
	var monitor_rate := DisplayServer.screen_get_refresh_rate(DisplayServer.window_get_current_screen())
	for rate in refresh_rates:
		if rate <= monitor_rate + 0.1:
			refresh_rate_option.add_item(str(rate) + " Hz", refresh_rates.find(rate))
	if refresh_rate_option.item_count == 0:
		refresh_rates.append(monitor_rate)
		refresh_rate_option.add_item(str(monitor_rate) + " Hz", refresh_rates.find(monitor_rate))

func _on_music_slider_changed(value: float) -> void:
	for player in get_tree().get_nodes_in_group("Music"):
		if player is AudioStreamPlayer or player is AudioStreamPlayer3D:
			player.volume_db = value

func _on_sound_slider_changed(value: float) -> void:
	for player in get_tree().get_nodes_in_group("Sound"):
		if player is AudioStreamPlayer or player is AudioStreamPlayer3D:
			player.volume_db = value

func _on_fullscreen_toggled(pressed: bool) -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if pressed else DisplayServer.WINDOW_MODE_WINDOWED)

func _on_vsync_toggled(pressed: bool) -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if pressed else DisplayServer.VSYNC_DISABLED)

	Engine.max_fps = 0

func _on_refresh_rate_selected(index: int) -> void:
	var selected_rate := refresh_rates[index]
	Engine.max_fps = int(selected_rate)


func _on_close_pressed() -> void:
	save_settings()
	visible = false
	var parent := get_parent()
	for button_name in ["Start", "Load", "Settings", "Exit"]:
		var button := parent.get_node_or_null(button_name)
		if button:
			button.visible = true

func _on_button_hover() -> void:
	var player_list := get_tree().get_nodes_in_group("Sound").filter(func(n): return n.name == "Button")
	if player_list.size() == 0:
		return
	var player := player_list[0] as AudioStreamPlayer
	if player:
		if player.playing:
			player.stop()
		player.play()

func save_settings():
	var config := ConfigFile.new()
	config.set_value("Settings", "volume_db", music_slider.value)
	config.set_value("Settings", "sound_volume_db", sound_slider.value)
	config.set_value("Settings", "fullscreen", fullscreen_checkbox.button_pressed)
	config.set_value("Settings", "vsync", vsync_checkbox.button_pressed)
	config.set_value("Settings", "refresh_rate", refresh_rates[refresh_rate_option.selected])
	config.save("user://settings.cfg")
