extends CanvasLayer

@export var ship_script: Node

@export var new_game_button: Button
@export var settings_button: Button
@export var exit_button: Button

@export var new_game_label: Label
@export var settings_label: Label
@export var exit_label: Label

@export var darkening: ColorRect
@export var canvas_group: Control  # используем Control вместо CanvasGroup

@export var waiting_darkening: float = 2.0
@export var duration_darkening: float = 3.0
@export var transparent_darkening: float = 1.0  # 0..1 в Godot

@export var wait_fade_in: float = 1.0
@export var fade_in_duration: float = 1.5
@export var wait_fade_out: float = 1.0
@export var fade_out_duration: float = 1.0

func _ready() -> void:
	# Подключаем кнопки
	new_game_button.pressed.connect(start_new_game)
	exit_button.pressed.connect(quit_game)
	
	add_hover_handler(new_game_button, new_game_label)
	add_hover_handler(settings_button, settings_label)
	add_hover_handler(exit_button, exit_label)

	# Изначально скрываем UI
	canvas_group.visible = true
	canvas_group.modulate.a = 0.0
	canvas_group.mouse_filter = Control.MOUSE_FILTER_IGNORE

	fade_in()

func quit_game() -> void:
	get_tree().quit()

func start_new_game() -> void:
	if ship_script:
		ship_script.call("start_new_game_animation")
	wait_darkening()
	fade_out()

func start_change_scene() -> void:
	get_tree().change_scene_to_file("res://YourNextScene.tscn")  # указать путь к сцене

func add_hover_handler(button: Button, label: Label) -> void:
	button.connect("mouse_entered", Callable(self, "_on_hover_enter").bind(label))
	button.connect("mouse_exited", Callable(self, "_on_hover_exit").bind(label))

func _on_hover_enter(label: Label) -> void:
	if label:
		label.modulate = Color8(210, 196, 196, 255)

func _on_hover_exit(label: Label) -> void:
	if label:
		label.modulate = Color.WHITE

func fade_in() -> void:
	canvas_group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	await get_tree().create_timer(wait_fade_in).timeout
	var timer = 0.0
	while timer < fade_in_duration:
		timer += get_process_delta_time()
		canvas_group.modulate.a = clamp(timer / fade_in_duration, 0.0, 1.0)
		await get_tree().process_frame
	canvas_group.mouse_filter = Control.MOUSE_FILTER_STOP

func fade_out() -> void:
	canvas_group.mouse_filter = Control.MOUSE_FILTER_IGNORE
	await get_tree().create_timer(wait_fade_out).timeout
	var timer = 0.0
	while timer < fade_out_duration:
		timer += get_process_delta_time()
		canvas_group.modulate.a = clamp(1.0 - (timer / fade_out_duration), 0.0, 1.0)
		await get_tree().process_frame
	canvas_group.modulate.a = 0.0

func wait_darkening() -> void:
	darkening.visible = true
	await get_tree().create_timer(waiting_darkening).timeout
	var timer = 0.0
	while timer < duration_darkening:
		timer += get_process_delta_time()
		darkening.color.a = clamp(timer / duration_darkening, 0.0, 1.0)
		await get_tree().process_frame
	start_change_scene()
