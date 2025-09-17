extends CharacterBody3D

const MOUSE_SENSITIVITY = 0.004
const SMOOTH_SPEED = 10

var smooth_x = 0.0
var smooth_y = 0.0

@export var speed: float = 5.0
@export var jump_velocity: float = -5.0  # Отрицательное значение для прыжка вверх
@export var gravity: float = 9.8

@onready var head: = $"."
@onready var camera: = $CameraPoint/Camera3D

func _unhandled_input(event: InputEvent):
	if event is InputEventMouseMotion:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED and event is InputEventMouseMotion:
		smooth_x = lerp(smooth_x, event.relative.x, SMOOTH_SPEED * get_process_delta_time())
		smooth_y = lerp(smooth_y, event.relative.y, SMOOTH_SPEED * get_process_delta_time())

		head.rotate_y(-smooth_x * MOUSE_SENSITIVITY)
		camera.rotate_x(clamp(-smooth_y * MOUSE_SENSITIVITY + camera.rotation.x, deg_to_rad(-80), deg_to_rad(80)) - camera.rotation.x)
	
	camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-30), deg_to_rad(60))

func _physics_process(delta):
	# Применяем гравитацию
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Получаем ввод
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction.length() > 0:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	# Прыжок
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity

	# Движение персонажа
	move_and_slide()
