extends Node3D   # если у тебя 2D — замени на Node2D

@export var residential_module: Node3D
@export var solar_panel1: Node3D

# Настройки вращения солнечной панели
@export var min_delay: float = 1.0
@export var max_delay: float = 3.0
@export var min_angle: float = 30.0
@export var max_angle: float = 180.0
@export var rotation_speed: float = 0.5  # градусов в секунду

# Настройки вращения жилого модуля
@export var residential_module_rotate_speed: float = 0.5

@export var animator: AnimationPlayer

var start_animation := false
var is_rotating := false
var target_angle_z := 0.0

func _ready() -> void:
	if animator:
		start_animation = animator.is_playing()
	rotation_cycle()

func _process(delta: float) -> void:
	update_animator_speed()
	rotate_residential_module(delta)
	update_solar_panel_rotation(delta)

func start_new_game_animation() -> void:
	if animator:
		animator.play("StartGame")
		start_animation = true

func update_animator_speed() -> void:
	if start_animation and animator:
		# В Godot нет animator.GetFloat("SpeedAnim"), 
		# поэтому нужно вручную настраивать скорость анимации
		# Тут я оставил минимум 0.3 как у тебя
		var curve_speed: float = animator.playback_speed
		curve_speed = max(0.3, curve_speed)
		animator.playback_speed = curve_speed

func rotate_residential_module(delta: float) -> void:
	if residential_module:
		residential_module.rotate_z(deg_to_rad(residential_module_rotate_speed * delta))

func update_solar_panel_rotation(delta: float) -> void:
	if not is_rotating or solar_panel1 == null:
		return

	var current_z = fmod(rad_to_deg(solar_panel1.rotation.z), 360.0)
	var angle_diff = wrapf(target_angle_z - current_z + 180.0, 0.0, 360.0) - 180.0
	var step = rotation_speed * delta

	if abs(angle_diff) > 0.1:
		var rotation_this_frame = clamp(angle_diff, -step, step)
		solar_panel1.rotate_z(deg_to_rad(rotation_this_frame))
	else:
		solar_panel1.rotation.z = deg_to_rad(target_angle_z)
		is_rotating = false

func rotation_cycle() -> void:
	await get_tree().process_frame
	while true:
		var delay = randf_range(min_delay, max_delay)
		await get_tree().create_timer(delay).timeout

		var current_z = fmod(rad_to_deg(residential_module.rotation.z), 360.0)
		var angle_to_add = randf_range(min_angle, max_angle)
		target_angle_z = (current_z + angle_to_add) % 360.0

		is_rotating = true
		while is_rotating:
			await get_tree().process_frame
