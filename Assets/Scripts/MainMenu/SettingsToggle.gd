extends Node

@export var settings_panel: Control
@export var open_settings_button: Button
@export var close_settings_button: Button

func _ready() -> void:
	if settings_panel:
		settings_panel.visible = false

	if open_settings_button:
		open_settings_button.pressed.connect(open_settings)

	if close_settings_button:
		close_settings_button.pressed.connect(close_settings)

func open_settings() -> void:
	if settings_panel:
		settings_panel.visible = true

func close_settings() -> void:
	if settings_panel:
		settings_panel.visible = false
