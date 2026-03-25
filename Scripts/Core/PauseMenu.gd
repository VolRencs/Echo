extends CanvasLayer

# ─── EXPORTS ──────────────────────────────────────────────────────────────────

@export_category("Buttons")
@export var continue_button: Button
@export var settings_button: Button
@export var quit_button:     Button

@export_category("Panels")
@export var control_panel: Control

# ─── CONSTANTS ────────────────────────────────────────────────────────────────

const MAIN_MENU_PATH := "res://Scene/MainMenu/MainMenu.tscn"

# ─── STATE ────────────────────────────────────────────────────────────────────

var menu_open:     bool = false
var _hover_sound:  AudioStreamPlayer
var _main_buttons: Array[Button]

# ─── READY ────────────────────────────────────────────────────────────────────

func _ready() -> void:
	visible = false
	if control_panel:
		control_panel.visible = false

	_hover_sound = NodeUtils.find_audio_stream_player(get_tree(), &"Button")

	_main_buttons = [continue_button, settings_button, quit_button]

	_bind_button(continue_button, _on_continue_pressed)
	_bind_button(settings_button, _on_settings_pressed)
	_bind_button(quit_button, _on_quit_pressed)

# ─── INPUT ────────────────────────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_toggle_menu()

# ─── MENU TOGGLE ──────────────────────────────────────────────────────────────

func _toggle_menu() -> void:
	menu_open = not menu_open
	visible   = menu_open

	Input.set_mouse_mode(
		Input.MOUSE_MODE_VISIBLE if menu_open else Input.MOUSE_MODE_CAPTURED
	)
	get_tree().paused = menu_open

	if menu_open:
		_set_settings_visible(false)

func _set_settings_visible(visible_settings: bool) -> void:
	if control_panel:
		control_panel.visible = visible_settings
	for btn in _main_buttons:
		if btn:
			btn.visible = not visible_settings

# ─── HANDLERS ─────────────────────────────────────────────────────────────────

func _on_continue_pressed() -> void:
	_toggle_menu()

func _on_settings_pressed() -> void:
	_set_settings_visible(true)

func _on_quit_pressed() -> void:
	var player := get_tree().get_first_node_in_group("Player")
	if player and player.has_method("save_position"):
		player.call("save_position")

	if get_tree().current_scene:
		var packed := PackedScene.new()
		if packed.pack(get_tree().current_scene) == OK:
			SaveManager.loaded_scene_data = packed

	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU_PATH)

func _on_button_hover() -> void:
	if _hover_sound:
		_hover_sound.stop()
		_hover_sound.play()

func _bind_button(button: Button, pressed_callback: Callable) -> void:
	if not button:
		return

	button.pressed.connect(pressed_callback)
	button.mouse_entered.connect(_on_button_hover)

# ─── PUBLIC API ───────────────────────────────────────────────────────────────

func close_settings() -> void:
	_set_settings_visible(false)

func open_menu() -> void:
	if not menu_open: _toggle_menu()

func close_menu() -> void:
	if menu_open: _toggle_menu()
