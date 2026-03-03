extends CanvasLayer

# ─── EXPORTS ──────────────────────────────────────────────────────────────────

@export_category("Buttons")
@export var start_button:    Button
@export var load_button:     Button
@export var settings_button: Button
@export var quit_button:     Button

@export_category("Panels")
@export var control_panel: Control

@export_category("Scenes")
@export var start_scene := "res://Scene/Core/Game.tscn"

# ─── STATE ────────────────────────────────────────────────────────────────────

var _hover_sound:   AudioStreamPlayer
var _main_buttons:  Array[Button]

# ─── READY ────────────────────────────────────────────────────────────────────

func _ready() -> void:
	SaveManager.load_game()

	if control_panel:
		control_panel.visible = false

	for node in get_tree().get_nodes_in_group("Sound"):
		if node.name == "Button" and node is AudioStreamPlayer:
			_hover_sound = node
			break

	_main_buttons = [start_button, load_button, settings_button, quit_button]

	var bindings := {
		start_button:    [_on_start_pressed],
		load_button:     [_on_load_pressed],
		settings_button: [_on_settings_pressed],
		quit_button:     [_on_quit_pressed],
	}
	for btn: Button in bindings:
		if btn:
			btn.pressed.connect(bindings[btn][0])
			btn.mouse_entered.connect(_on_button_hover)

	_refresh_load_button()

# ─── BUTTON HANDLERS ──────────────────────────────────────────────────────────

func _on_start_pressed() -> void:
	if SaveManager.has_save():
		_show_overwrite_dialog()
	else:
		_start_new_game()

func _on_load_pressed() -> void:
	if SaveManager.loaded_player_data.is_empty() or not SaveManager.loaded_scene_data:
		return
	get_tree().change_scene_to_packed(SaveManager.loaded_scene_data)

func _on_settings_pressed() -> void:
	_toggle_settings(true)

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_button_hover() -> void:
	if _hover_sound:
		_hover_sound.stop()
		_hover_sound.play()

# ─── LOGIC ────────────────────────────────────────────────────────────────────

func _show_overwrite_dialog() -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title       = "Подтверждение"
	dialog.dialog_text = "Сохранение найдено. Начать новую игру и перезаписать его?"
	dialog.confirmed.connect(_start_new_game)
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)
	dialog.close_requested.connect(dialog.queue_free)
	add_child(dialog)
	dialog.popup_centered()

func _start_new_game() -> void:
	SaveManager.clear_loaded_data()
	SaveManager.delete_save()
	get_tree().change_scene_to_file(start_scene)

func _toggle_settings(show_settings: bool) -> void:
	if control_panel:
		control_panel.visible = show_settings
	for btn in _main_buttons:
		if btn:
			btn.visible = not show_settings

func _refresh_load_button() -> void:
	if load_button:
		load_button.disabled = SaveManager.loaded_player_data.is_empty()

# ─── PUBLIC API ───────────────────────────────────────────────────────────────

func close_settings() -> void:
	_toggle_settings(false)

func refresh_load_button() -> void:
	_refresh_load_button()
