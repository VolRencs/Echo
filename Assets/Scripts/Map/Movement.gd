extends CharacterBody3D

# Константы
const MOUSE_SENSITIVITY: float = 0.002  # Уменьшено для более резкого отклика
const MAX_PITCH: float = deg_to_rad(60.0)  # Максимальный угол вверх
const MIN_PITCH: float = deg_to_rad(-30.0)  # Максимальный угол вниз
const SMOOTH_SPEED: float = 20.0  # Увеличено для более быстрого сглаживания

# Переменные
var rotation_x: float = 0.0  # Горизонтальная ротация (yaw)
var rotation_y: float = 0.0  # Вертикальная ротация (pitch)

@export var speed: float = 5.0
@export var jump_velocity: float = -5.0  # Отрицательное значение для прыжка вверх
@export var gravity: float = 9.8
@export var friction: float = 10.0  # Новая переменная для замедления

@onready var camera: Camera3D = $CameraPoint/Camera3D  # Корректное объявление с типом

func _ready():
	if not camera:
		push_error("Camera3D not found! Check the node hierarchy.")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)  # Захват мыши по умолчанию

func _unhandled_input(event: InputEvent):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		# Сглаживание движения мыши с меньшей плавностью
		rotation_x = lerp(rotation_x, event.relative.x * MOUSE_SENSITIVITY, SMOOTH_SPEED * get_process_delta_time())
		rotation_y = lerp(rotation_y, event.relative.y * MOUSE_SENSITIVITY, SMOOTH_SPEED * get_process_delta_time())

		# Применяем ротацию
		rotate_y(-rotation_x)
		camera.rotation.x = clamp(camera.rotation.x - rotation_y, MIN_PITCH, MAX_PITCH)

func _physics_process(delta):
	# Применяем гравитацию
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Получаем ввод
	var input_dir = Input.get_vector("left", "right", "up", "down")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction.length() > 0:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		# Улучшенное торможение с учётом friction
		velocity.x = move_toward(velocity.x, 0, friction * delta)
		velocity.z = move_toward(velocity.z, 0, friction * delta)

	# Прыжок
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_velocity

	# Движение персонажа
	move_and_slide()
