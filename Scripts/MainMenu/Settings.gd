extends Control

# ─── EXPORTS ──────────────────────────────────────────────────────────────────

@export_category("UI Elements")
@export var music_slider:        HSlider
@export var sound_slider:        HSlider
@export var fullscreen_checkbox: CheckBox
@export var vsync_checkbox:      CheckBox
@export var refresh_rate_option: OptionButton
@export var close_button:        Button

# ─── CONSTANTS ────────────────────────────────────────────────────────────────

const SETTINGS_PATH  := "user://settings.cfg"
const SECTION        := "Settings"
const MIN_VOLUME     := -40.0
const MAX_VOLUME     :=   0.0
const MUTE_VOLUME    := -80.0

const REFRESH_RATES: Array[float] = [60.0, 75.0, 100.0, 120.0, 144.0, 165.0, 180.0, 240.0]

const DEFAULTS := {
	"volume_db":       0.0,
	"sound_volume_db": 0.0,
	"fullscreen":      false,
	"vsync":           true,
	"refresh_rate":    60.0,
}

# ─── STATE ────────────────────────────────────────────────────────────────────

var _hover_sound:  AudioStreamPlayer
var _music_nodes:  Array
var _sound_nodes:  Array

# ─── READY ────────────────────────────────────────────────────────────────────

func _ready() -> void:
	_music_nodes = get_tree().get_nodes_in_group("Music")
	_sound_nodes = get_tree().get_nodes_in_group("Sound")

	for node in _sound_nodes:
		if node.name == "Button" and node is AudioStreamPlayer:
			_hover_sound = node
			break

	_setup_sliders()
	_setup_signals()
	_populate_refresh_rates()
	_load_settings()

# ─── SETUP ────────────────────────────────────────────────────────────────────

func _setup_sliders() -> void:
	for slider: HSlider in [music_slider, sound_slider]:
		if slider:
			slider.min_value = MIN_VOLUME
			slider.max_value = MAX_VOLUME

	if music_slider and not _music_nodes.is_empty():
		music_slider.value = _music_nodes[0].volume_db

	if sound_slider and not _sound_nodes.is_empty():
		sound_slider.value = _sound_nodes[0].volume_db

func _setup_signals() -> void:
	if music_slider:        music_slider.value_changed.connect(_on_music_slider_changed)
	if sound_slider:        sound_slider.value_changed.connect(_on_sound_slider_changed)
	if fullscreen_checkbox: fullscreen_checkbox.toggled.connect(_on_fullscreen_toggled)
	if vsync_checkbox:      vsync_checkbox.toggled.connect(_on_vsync_toggled)
	if refresh_rate_option: refresh_rate_option.item_selected.connect(_on_refresh_rate_selected)

	if close_button:
		close_button.pressed.connect(_on_close_pressed)
		close_button.mouse_entered.connect(_on_button_hover)

	if fullscreen_checkbox:
		fullscreen_checkbox.button_pressed = \
			DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN

func _populate_refresh_rates() -> void:
	if not refresh_rate_option:
		return

	refresh_rate_option.clear()
	var monitor_rate := DisplayServer.screen_get_refresh_rate(
		DisplayServer.window_get_current_screen()
	)

	var added := false
	for rate in REFRESH_RATES:
		if rate <= monitor_rate + 0.1:
			refresh_rate_option.add_item("%d Hz" % int(rate))
			added = true

	if not added:
		refresh_rate_option.add_item("%d Hz" % int(monitor_rate))

# ─── SETTINGS I/O ─────────────────────────────────────────────────────────────

func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		_apply_settings(DEFAULTS)
		return

	var data := {
		"volume_db":       config.get_value(SECTION, "volume_db",       DEFAULTS.volume_db),
		"sound_volume_db": config.get_value(SECTION, "sound_volume_db", DEFAULTS.sound_volume_db),
		"fullscreen":      config.get_value(SECTION, "fullscreen",      DEFAULTS.fullscreen),
		"vsync":           config.get_value(SECTION, "vsync",           DEFAULTS.vsync),
		"refresh_rate":    config.get_value(SECTION, "refresh_rate",    DEFAULTS.refresh_rate),
	}
	_apply_settings(data)

func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value(SECTION, "volume_db",       music_slider.value        if music_slider        else DEFAULTS.volume_db)
	config.set_value(SECTION, "sound_volume_db", sound_slider.value        if sound_slider        else DEFAULTS.sound_volume_db)
	config.set_value(SECTION, "fullscreen",      fullscreen_checkbox.button_pressed if fullscreen_checkbox else DEFAULTS.fullscreen)
	config.set_value(SECTION, "vsync",           vsync_checkbox.button_pressed      if vsync_checkbox      else DEFAULTS.vsync)

	var idx := refresh_rate_option.selected if refresh_rate_option else -1
	config.set_value(SECTION, "refresh_rate",
		REFRESH_RATES[idx] if idx >= 0 and idx < REFRESH_RATES.size() else DEFAULTS.refresh_rate
	)

	var err := config.save(SETTINGS_PATH)
	if err != OK:
		push_error("Settings: save failed (error %d)" % err)

func _apply_settings(data: Dictionary) -> void:
	if music_slider:
		music_slider.value = data.volume_db
		_on_music_slider_changed(data.volume_db)

	if sound_slider:
		sound_slider.value = data.sound_volume_db
		_on_sound_slider_changed(data.sound_volume_db)

	if fullscreen_checkbox:
		fullscreen_checkbox.button_pressed = data.fullscreen
		_on_fullscreen_toggled(data.fullscreen)

	if vsync_checkbox:
		vsync_checkbox.button_pressed = data.vsync
		_on_vsync_toggled(data.vsync)

	if refresh_rate_option:
		var idx := REFRESH_RATES.find(data.refresh_rate)
		if idx >= 0 and idx < refresh_rate_option.item_count:
			refresh_rate_option.select(idx)
			_on_refresh_rate_selected(idx)

# ─── SIGNAL HANDLERS ──────────────────────────────────────────────────────────

func _on_music_slider_changed(value: float) -> void:
	_set_group_volume(_music_nodes, value)

func _on_sound_slider_changed(value: float) -> void:
	_set_group_volume(_sound_nodes, value)

func _on_fullscreen_toggled(pressed: bool) -> void:
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if pressed else DisplayServer.WINDOW_MODE_WINDOWED
	)

func _on_vsync_toggled(pressed: bool) -> void:
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if pressed else DisplayServer.VSYNC_DISABLED
	)
	Engine.max_fps = 0

func _on_refresh_rate_selected(index: int) -> void:
	if index >= 0 and index < REFRESH_RATES.size():
		Engine.max_fps = int(REFRESH_RATES[index])

func _on_close_pressed() -> void:
	save_settings()
	visible = false
	var parent := get_parent()
	if parent and parent.has_method("close_settings"):
		parent.close_settings()

func _on_button_hover() -> void:
	if _hover_sound:
		_hover_sound.stop()
		_hover_sound.play()

# ─── HELPERS ──────────────────────────────────────────────────────────────────

func _set_group_volume(nodes: Array, volume: float) -> void:
	var db := MUTE_VOLUME if volume <= MIN_VOLUME else volume
	for node in nodes:
		if node is AudioStreamPlayer or node is AudioStreamPlayer2D or node is AudioStreamPlayer3D:
			node.volume_db = db

# ─── PUBLIC API ───────────────────────────────────────────────────────────────

func reset_to_defaults() -> void:
	_apply_settings(DEFAULTS)
	save_settings()
