extends Control

@export_category("UI Elements")
@export var music_slider: HSlider
@export var sound_slider: HSlider
@export var fullscreen_checkbox: CheckBox
@export var vsync_checkbox: CheckBox
@export var refresh_rate_option: OptionButton
@export var close_button: Button

const SETTINGS_PATH := "user://settings.cfg"
const MIN_VOLUME := -40.0
const MAX_VOLUME := 0.0
const MUTE_VOLUME := -80.0

const REFRESH_RATES: Array[float] = [60.0, 75.0, 100.0, 120.0, 144.0, 165.0, 180.0, 240.0]

var _hover_sound: AudioStreamPlayer = null
var _music_nodes: Array = []
var _sound_nodes: Array = []

func _ready() -> void:
	_cache_audio_nodes()
	_setup_sliders()
	_setup_signals()
	_populate_refresh_rates()
	_load_settings()

func _cache_audio_nodes() -> void:
	_music_nodes = get_tree().get_nodes_in_group("Music")
	_sound_nodes = get_tree().get_nodes_in_group("Sound")
	
	for node in _sound_nodes:
		if node.name == "Button" and node is AudioStreamPlayer:
			_hover_sound = node
			break

func _setup_sliders() -> void:
	for slider in [music_slider, sound_slider]:
		if slider:
			slider.min_value = MIN_VOLUME
			slider.max_value = MAX_VOLUME
	
	if music_slider and _music_nodes.size() > 0:
		music_slider.value = _music_nodes[0].volume_db
	
	if sound_slider and _sound_nodes.size() > 0:
		sound_slider.value = _sound_nodes[0].volume_db

func _setup_signals() -> void:
	if music_slider:
		music_slider.value_changed.connect(_on_music_slider_changed)
	
	if sound_slider:
		sound_slider.value_changed.connect(_on_sound_slider_changed)
	
	if fullscreen_checkbox:
		fullscreen_checkbox.toggled.connect(_on_fullscreen_toggled)
		fullscreen_checkbox.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	
	if vsync_checkbox:
		vsync_checkbox.toggled.connect(_on_vsync_toggled)
	
	if refresh_rate_option:
		refresh_rate_option.item_selected.connect(_on_refresh_rate_selected)
	
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
		close_button.mouse_entered.connect(_on_button_hover)

func _populate_refresh_rates() -> void:
	if not refresh_rate_option:
		return
	
	refresh_rate_option.clear()
	
	var current_screen := DisplayServer.window_get_current_screen()
	var monitor_rate := DisplayServer.screen_get_refresh_rate(current_screen)
	
	for rate in REFRESH_RATES:
		if rate <= monitor_rate + 0.1:
			refresh_rate_option.add_item("%d Hz" % int(rate))
	
	if refresh_rate_option.item_count == 0:
		refresh_rate_option.add_item("%d Hz" % int(monitor_rate))

func _load_settings() -> void:
	var config: ConfigFile = ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	
	var music_vol: float = config.get_value("Settings", "volume_db", 0.0)
	var sound_vol: float = config.get_value("Settings", "sound_volume_db", 0.0)
	var is_fullscreen: bool = config.get_value("Settings", "fullscreen", false)
	var is_vsync: bool = config.get_value("Settings", "vsync", true)
	var saved_rate: float = config.get_value("Settings", "refresh_rate", 60.0)
	
	if music_slider:
		music_slider.value = music_vol
		_on_music_slider_changed(music_vol)
	
	if sound_slider:
		sound_slider.value = sound_vol
		_on_sound_slider_changed(sound_vol)
	
	if fullscreen_checkbox:
		fullscreen_checkbox.button_pressed = is_fullscreen
		_on_fullscreen_toggled(is_fullscreen)
	
	if vsync_checkbox:
		vsync_checkbox.button_pressed = is_vsync
		_on_vsync_toggled(is_vsync)
	
	if refresh_rate_option:
		var rate_index := REFRESH_RATES.find(saved_rate)
		if rate_index >= 0 and rate_index < refresh_rate_option.item_count:
			refresh_rate_option.select(rate_index)
			_on_refresh_rate_selected(rate_index)

func save_settings() -> void:
	if not music_slider or not sound_slider or not fullscreen_checkbox or not vsync_checkbox or not refresh_rate_option:
		push_warning("Settings: Cannot save, some UI elements are missing")
		return
	
	var config: ConfigFile = ConfigFile.new()
	config.set_value("Settings", "volume_db", music_slider.value)
	config.set_value("Settings", "sound_volume_db", sound_slider.value)
	config.set_value("Settings", "fullscreen", fullscreen_checkbox.button_pressed)
	config.set_value("Settings", "vsync", vsync_checkbox.button_pressed)
	
	var selected_idx := refresh_rate_option.selected
	if selected_idx >= 0 and selected_idx < REFRESH_RATES.size():
		config.set_value("Settings", "refresh_rate", REFRESH_RATES[selected_idx])
	
	var err := config.save(SETTINGS_PATH)
	if err != OK:
		push_error("Settings: Failed to save settings, error code: %d" % err)

func _set_group_volume(nodes: Array, volume: float) -> void:
	var final_volume := MUTE_VOLUME if volume <= MIN_VOLUME else volume
	
	for node in nodes:
		if node is AudioStreamPlayer or node is AudioStreamPlayer2D or node is AudioStreamPlayer3D:
			node.volume_db = final_volume

func _on_music_slider_changed(value: float) -> void:
	_set_group_volume(_music_nodes, value)

func _on_sound_slider_changed(value: float) -> void:
	_set_group_volume(_sound_nodes, value)

func _on_fullscreen_toggled(is_pressed: bool) -> void:
	var mode := DisplayServer.WINDOW_MODE_FULLSCREEN if is_pressed else DisplayServer.WINDOW_MODE_WINDOWED
	DisplayServer.window_set_mode(mode)

func _on_vsync_toggled(is_pressed: bool) -> void:
	var vsync_mode := DisplayServer.VSYNC_ENABLED if is_pressed else DisplayServer.VSYNC_DISABLED
	DisplayServer.window_set_vsync_mode(vsync_mode)
	Engine.max_fps = 0

func _on_refresh_rate_selected(index: int) -> void:
	if index < 0 or index >= REFRESH_RATES.size():
		return
	
	var selected_rate := REFRESH_RATES[index]
	Engine.max_fps = int(selected_rate)

func _on_close_pressed() -> void:
	save_settings()
	_close_settings_panel()

func _close_settings_panel() -> void:
	visible = false
	
	var parent := get_parent()
	if parent and parent.has_method("close_settings"):
		parent.close_settings()
	else:
		_show_menu_buttons()

func _show_menu_buttons() -> void:
	var parent := get_parent()
	if not parent:
		return
	
	for button_name in ["Start", "Load", "Settings", "Exit"]:
		var button := parent.get_node_or_null(button_name)
		if button:
			button.visible = true

func _on_button_hover() -> void:
	if _hover_sound:
		_hover_sound.stop()
		_hover_sound.play()

func reset_to_defaults() -> void:
	if music_slider:
		music_slider.value = 0.0
		_on_music_slider_changed(0.0)
	
	if sound_slider:
		sound_slider.value = 0.0
		_on_sound_slider_changed(0.0)
	
	if fullscreen_checkbox:
		fullscreen_checkbox.button_pressed = false
		_on_fullscreen_toggled(false)
	
	if vsync_checkbox:
		vsync_checkbox.button_pressed = true
		_on_vsync_toggled(true)
	
	if refresh_rate_option and refresh_rate_option.item_count > 0:
		refresh_rate_option.select(0)
		_on_refresh_rate_selected(0)
	
	save_settings()
