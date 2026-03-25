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
const DEFAULT_VOLUME_DB := 0.0
const DEFAULT_SOUND_VOLUME_DB := 0.0
const DEFAULT_FULLSCREEN := false
const DEFAULT_VSYNC := true
const DEFAULT_REFRESH_RATE := 60.0

const REFRESH_RATES: Array[float] = [60.0, 75.0, 100.0, 120.0, 144.0, 165.0, 180.0, 240.0]

const DEFAULTS := {
	"volume_db":       DEFAULT_VOLUME_DB,
	"sound_volume_db": DEFAULT_SOUND_VOLUME_DB,
	"fullscreen":      DEFAULT_FULLSCREEN,
	"vsync":           DEFAULT_VSYNC,
	"refresh_rate":    DEFAULT_REFRESH_RATE,
}

# ─── STATE ────────────────────────────────────────────────────────────────────

var _hover_sound:  AudioStreamPlayer
var _music_nodes:  Array[Node] = []
var _sound_nodes:  Array[Node] = []
var _available_refresh_rates: Array[float] = []

# ─── READY ────────────────────────────────────────────────────────────────────

func _ready() -> void:
	_music_nodes = get_tree().get_nodes_in_group("Music")
	_sound_nodes = get_tree().get_nodes_in_group("Sound")
	_hover_sound = NodeUtils.find_audio_stream_player(get_tree(), &"Button")

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
		music_slider.value = _get_audio_node_volume(_music_nodes[0], DEFAULT_VOLUME_DB)

	if sound_slider and not _sound_nodes.is_empty():
		sound_slider.value = _get_audio_node_volume(_sound_nodes[0], DEFAULT_SOUND_VOLUME_DB)

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

	_available_refresh_rates.clear()
	refresh_rate_option.clear()
	var monitor_rate := DisplayServer.screen_get_refresh_rate(
		DisplayServer.window_get_current_screen()
	)
	if monitor_rate <= 0.0:
		monitor_rate = DEFAULT_REFRESH_RATE

	for rate in REFRESH_RATES:
		if rate <= monitor_rate + 0.1:
			_available_refresh_rates.append(rate)
			refresh_rate_option.add_item("%d Hz" % int(rate))

	if _available_refresh_rates.is_empty():
		_available_refresh_rates.append(monitor_rate)
		refresh_rate_option.add_item("%d Hz" % int(monitor_rate))

# ─── SETTINGS I/O ─────────────────────────────────────────────────────────────

func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		_apply_settings(DEFAULTS)
		return

	var data := {
		"volume_db":       config.get_value(SECTION, "volume_db",       DEFAULT_VOLUME_DB),
		"sound_volume_db": config.get_value(SECTION, "sound_volume_db", DEFAULT_SOUND_VOLUME_DB),
		"fullscreen":      config.get_value(SECTION, "fullscreen",      DEFAULT_FULLSCREEN),
		"vsync":           config.get_value(SECTION, "vsync",           DEFAULT_VSYNC),
		"refresh_rate":    config.get_value(SECTION, "refresh_rate",    DEFAULT_REFRESH_RATE),
	}
	_apply_settings(data)

func save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value(SECTION, "volume_db",       music_slider.value if music_slider else DEFAULT_VOLUME_DB)
	config.set_value(SECTION, "sound_volume_db", sound_slider.value if sound_slider else DEFAULT_SOUND_VOLUME_DB)
	config.set_value(
		SECTION,
		"fullscreen",
		fullscreen_checkbox.button_pressed if fullscreen_checkbox else DEFAULT_FULLSCREEN
	)
	config.set_value(
		SECTION,
		"vsync",
		vsync_checkbox.button_pressed if vsync_checkbox else DEFAULT_VSYNC
	)

	var idx := refresh_rate_option.selected if refresh_rate_option else -1
	config.set_value(SECTION, "refresh_rate",
		_available_refresh_rates[idx]
		if idx >= 0 and idx < _available_refresh_rates.size()
		else DEFAULT_REFRESH_RATE
	)

	var err := config.save(SETTINGS_PATH)
	if err != OK:
		push_error("Settings: save failed (error %d)" % err)

func _apply_settings(data: Dictionary) -> void:
	var music_value := float(data.get("volume_db", DEFAULT_VOLUME_DB))
	var sound_value := float(data.get("sound_volume_db", DEFAULT_SOUND_VOLUME_DB))
	var fullscreen := bool(data.get("fullscreen", DEFAULT_FULLSCREEN))
	var vsync := bool(data.get("vsync", DEFAULT_VSYNC))
	var refresh_rate := float(data.get("refresh_rate", DEFAULT_REFRESH_RATE))

	if music_slider:
		music_slider.value = music_value
		_on_music_slider_changed(music_value)

	if sound_slider:
		sound_slider.value = sound_value
		_on_sound_slider_changed(sound_value)

	if fullscreen_checkbox:
		fullscreen_checkbox.button_pressed = fullscreen
		_on_fullscreen_toggled(fullscreen)

	if vsync_checkbox:
		vsync_checkbox.button_pressed = vsync
		_on_vsync_toggled(vsync)

	if refresh_rate_option:
		var idx := _find_refresh_rate_index(refresh_rate)
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
	if index >= 0 and index < _available_refresh_rates.size():
		Engine.max_fps = int(_available_refresh_rates[index])

func _on_close_pressed() -> void:
	save_settings()
	visible = false
	var parent := get_parent()
	if parent and parent.has_method("close_settings"):
		parent.call("close_settings")

func _on_button_hover() -> void:
	if _hover_sound:
		_hover_sound.stop()
		_hover_sound.play()

# ─── HELPERS ──────────────────────────────────────────────────────────────────

func _set_group_volume(nodes: Array[Node], volume: float) -> void:
	var db := MUTE_VOLUME if volume <= MIN_VOLUME else volume
	for node: Node in nodes:
		_set_audio_node_volume(node, db)

func _get_audio_node_volume(node: Node, fallback: float) -> float:
	if node is AudioStreamPlayer:
		return (node as AudioStreamPlayer).volume_db
	if node is AudioStreamPlayer2D:
		return (node as AudioStreamPlayer2D).volume_db
	if node is AudioStreamPlayer3D:
		return (node as AudioStreamPlayer3D).volume_db
	return fallback

func _set_audio_node_volume(node: Node, volume_db: float) -> void:
	if node is AudioStreamPlayer:
		(node as AudioStreamPlayer).volume_db = volume_db
	elif node is AudioStreamPlayer2D:
		(node as AudioStreamPlayer2D).volume_db = volume_db
	elif node is AudioStreamPlayer3D:
		(node as AudioStreamPlayer3D).volume_db = volume_db

func _find_refresh_rate_index(target_rate: float) -> int:
	if _available_refresh_rates.is_empty():
		return -1

	var closest_index := 0
	var closest_diff := absf(_available_refresh_rates[0] - target_rate)
	for index in range(1, _available_refresh_rates.size()):
		var diff := absf(_available_refresh_rates[index] - target_rate)
		if diff < closest_diff:
			closest_diff = diff
			closest_index = index
	return closest_index

# ─── PUBLIC API ───────────────────────────────────────────────────────────────

func reset_to_defaults() -> void:
	_apply_settings(DEFAULTS)
	save_settings()
