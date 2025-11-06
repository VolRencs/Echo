extends CharacterBody3D

const MOUSE_SENSITIVITY: float = 0.0015
const MAX_PITCH: float = deg_to_rad(80.0)
const MIN_PITCH: float = deg_to_rad(-60.0)
const WALK_SPEED: float = 5.0
const SPRINT_SPEED: float = 8.0
const CROUCH_SPEED: float = 2.5
const ACCELERATION: float = 15.0
const DECELERATION: float = 20.0
const JUMP_VELOCITY: float = 4.5
const GRAVITY: float = 12.5
const STAND_CAMERA_HEIGHT: float = 3.2
const CROUCH_CAMERA_HEIGHT: float = 1.5
const CROUCH_HEIGHT: float = 0.5
const NORMAL_HEIGHT: float = 1.1
const CAMERA_SMOOTH_SPEED: float = 10.0
const SPRINT_FOV: float = 80.0
const NORMAL_FOV: float = 70.0
const CROUCH_FOV: float = 65.0
const SAVE_PATH = "user://game_save.tres"

@onready var camera: Camera3D = $Camera3D
@onready var collision_shape: CollisionShape3D = $Character
@onready var animation_player: AnimationPlayer = $Player_Model/AnimationPlayer
@onready var inventory: Control = $"../Inventory"

var current_speed: float = WALK_SPEED
var target_fov: float = NORMAL_FOV
var is_crouching: bool = false
var is_sprinting: bool = false
var is_jumping: bool = false
var rotation_y: float = 0.0
var step_timer: float = 0.0
var step_interval: float = 1.0
var camera_offset: float = STAND_CAMERA_HEIGHT

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	camera.position.y = camera_offset
	if not GameState.loaded_player_data.is_empty():
		position = GameState.loaded_player_data.get("position", position)
		rotation.y = GameState.loaded_player_data.get("rotation_y", rotation.y)
		GameState.clear_loaded_data()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		rotation_y = clamp(rotation_y - event.relative.y * MOUSE_SENSITIVITY, MIN_PITCH, MAX_PITCH)
		camera.rotation.x = rotation_y

func _physics_process(delta: float) -> void:
	velocity.y -= GRAVITY * delta if not is_on_floor() else 0.0
	is_jumping = false if is_on_floor() else is_jumping

	_handle_crouching(delta)
	_handle_sprinting()

	var input_dir: Vector2 = Input.get_vector("left", "right", "up", "down")
	var direction: Vector3 = (transform.basis.z * input_dir.y + transform.basis.x * input_dir.x).normalized() if input_dir.length() > 0 else Vector3.ZERO

	if is_jumping:
		if animation_player.current_animation != "Jump":
			animation_player.play("Jump", 0.2)
	elif input_dir.length() > 0:
		animation_player.play("Crouch_Walk" if is_crouching else "Running" if is_sprinting else "Walk", 0.2)
	else:
		animation_player.play("Crouch_Idle" if is_crouching else "Idle", 0.2)

	if is_on_floor():
		var speed_multiplier = ACCELERATION if direction.length() > 0 else DECELERATION
		velocity.x = lerp(velocity.x, direction.x * current_speed, speed_multiplier * delta)
		velocity.z = lerp(velocity.z, direction.z * current_speed, speed_multiplier * delta)

	if Input.is_action_just_pressed("ui_accept") and is_on_floor() and not is_crouching:
		is_jumping = true
		velocity.y = JUMP_VELOCITY
		animation_player.play("Jump", 0.2)

	camera.fov = lerp(camera.fov, target_fov, CAMERA_SMOOTH_SPEED * delta)

	var horizontal_velocity := Vector2(velocity.x, velocity.z).length()
	if horizontal_velocity > 0.1 and is_on_floor() and not is_crouching:
		step_timer -= delta
		if step_timer <= 0.0:
			for player in get_tree().get_nodes_in_group("Sound"):
				if player.name == "Step" and player is AudioStreamPlayer:
					player.stop()
					player.pitch_scale = randf_range(0.8, 1.2)
					player.play()
					break
			step_timer = step_interval / (current_speed / WALK_SPEED)
	else:
		step_timer = 0.0

	move_and_slide()

func _handle_crouching(delta: float) -> void:
	var target_height: float = CROUCH_HEIGHT if Input.is_action_pressed("crouch") else NORMAL_HEIGHT
	(collision_shape.shape as CapsuleShape3D).height = lerp(collision_shape.shape.height, target_height, 10.0 * delta)

	camera_offset = CROUCH_CAMERA_HEIGHT if Input.is_action_pressed("crouch") else STAND_CAMERA_HEIGHT
	camera.position.y = lerp(camera.position.y, camera_offset, 10.0 * delta)

	if $Head:
		$Head.disabled = Input.is_action_pressed("crouch")

	is_crouching = Input.is_action_pressed("crouch")
	target_fov = CROUCH_FOV if is_crouching else NORMAL_FOV

func _handle_sprinting() -> void:
	var input_dir: Vector2 = Input.get_vector("left", "right", "up", "down")
	is_sprinting = Input.is_action_pressed("sprint") and is_on_floor() and not is_crouching and input_dir.y < 0
	current_speed = SPRINT_SPEED if is_sprinting else (CROUCH_SPEED if is_crouching else WALK_SPEED)
	target_fov = SPRINT_FOV if is_sprinting else (CROUCH_FOV if is_crouching else NORMAL_FOV)

func save_position() -> void:
	var save_data = GameSave.new()
	save_data.player_data = {"position": position, "rotation_y": rotation.y}
	if get_tree().current_scene and get_tree().current_scene.name == "Game":
		var packed_scene = PackedScene.new()
		if packed_scene.pack(get_tree().current_scene) == OK:
			save_data.scene_data = packed_scene
	ResourceSaver.save(save_data, SAVE_PATH)
