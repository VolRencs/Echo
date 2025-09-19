extends CharacterBody3D

# Константы движения
const MOUSE_SENSITIVITY: float = 0.0015
const MAX_PITCH: float = deg_to_rad(80.0)
const MIN_PITCH: float = deg_to_rad(-60.0)
const WALK_SPEED: float = 5.0
const SPRINT_SPEED: float = 8.0
const CROUCH_SPEED: float = 2.5
const ACCELERATION: float = 15.0
const DECELERATION: float = 20.0
const JUMP_VELOCITY: float = 4.5
const GRAVITY: float = 9.81
const CROUCH_HEIGHT: float = 0.5
const NORMAL_HEIGHT: float = 1.8
const CAMERA_SMOOTH_SPEED: float = 10.0
const SPRINT_FOV: float = 80.0
const NORMAL_FOV: float = 70.0
const CROUCH_FOV: float = 65.0

# Ссылки на узлы
@onready var camera: Camera3D = $CameraPoint/Camera3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var camera_pivot: Node3D = $CameraPoint

# Переменные состояния
var current_speed: float = WALK_SPEED
var target_fov: float = NORMAL_FOV
var is_crouching: bool = false
var is_sprinting: bool = false
var rotation_x: float = 0.0
var rotation_y: float = 0.0
var step_timer := 0.0
var step_interval := 1.0

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	camera_pivot.rotation.x = rotation_y
	rotation.y = rotation_x

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotation_x -= event.relative.x * MOUSE_SENSITIVITY
		rotation_y -= event.relative.y * MOUSE_SENSITIVITY
		rotation_y = clamp(rotation_y, MIN_PITCH, MAX_PITCH)
		
		camera_pivot.rotation.x = rotation_y

		rotation.y = rotation_x

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0

	_handle_crouching(delta)
	_handle_sprinting()

	var input_dir: Vector2 = Input.get_vector("left", "right", "up", "down")
	var direction: Vector3 = Vector3.ZERO

	if input_dir.length() > 0:
		var forward: Vector3 = transform.basis.z
		var right: Vector3 = transform.basis.x
		forward.y = 0
		right.y = 0
		forward = forward.normalized()
		right = right.normalized()

		direction = (forward * input_dir.y + right * input_dir.x).normalized()

	velocity.x = lerp(velocity.x, direction.x * current_speed, ACCELERATION * delta if direction.length() > 0 else DECELERATION * delta)
	velocity.z = lerp(velocity.z, direction.z * current_speed, ACCELERATION * delta if direction.length() > 0 else DECELERATION * delta)

	# Прыжок
	if Input.is_action_just_pressed("ui_accept") and is_on_floor() and not is_crouching:
		velocity.y = JUMP_VELOCITY

	camera.fov = lerp(camera.fov, target_fov, CAMERA_SMOOTH_SPEED * delta)

	var horizontal_velocity := Vector3(velocity.x, 0, velocity.z).length()
	if horizontal_velocity > 0.1 and is_on_floor() and not is_crouching:
		step_timer -= delta
		if step_timer <= 0.0:
			if AudioManager.has_node("StepAudio"):
				var step_player = AudioManager.get_node("StepAudio") as AudioStreamPlayer
				if step_player.playing:
					step_player.stop()
				step_player.pitch_scale = randf_range(0.8, 1.2)
				step_player.play()
			step_timer = step_interval / (current_speed / WALK_SPEED)
	else:
		step_timer = 0.0
	move_and_slide()
	

func _handle_crouching(delta: float) -> void:
	var target_height: float = NORMAL_HEIGHT
	if Input.is_action_pressed("crouch"):
		target_height = CROUCH_HEIGHT

	var shape: CapsuleShape3D = collision_shape.shape as CapsuleShape3D
	shape.height = lerp(shape.height, target_height, 10.0 * delta)

	var target_camera_y: float = target_height - 0.2
	camera_pivot.position.y = lerp(camera_pivot.position.y, target_camera_y, 10.0 * delta)

	is_crouching = Input.is_action_pressed("crouch")
	target_fov = CROUCH_FOV if is_crouching else NORMAL_FOV

func _handle_sprinting() -> void:
	is_sprinting = Input.is_action_pressed("sprint") and is_on_floor() and not is_crouching
	current_speed = SPRINT_SPEED if is_sprinting else (CROUCH_SPEED if is_crouching else WALK_SPEED)
	target_fov = SPRINT_FOV if is_sprinting else (CROUCH_FOV if is_crouching else NORMAL_FOV)
