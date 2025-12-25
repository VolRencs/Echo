extends CharacterBody3D

@export_category("Mouse")
@export var mouse_sensitivity := 0.0015
@export var max_pitch_deg := 80.0
@export var min_pitch_deg := -60.0

@export_category("Movement")
@export var walk_speed := 5.0
@export var sprint_speed := 8.0
@export var crouch_speed := 2.5
@export var acceleration := 15.0
@export var deceleration := 20.0

@export_category("Jump & Gravity")
@export var jump_velocity := 4.5
@export var gravity := 12.5

@export_category("Crouch")
@export var stand_camera_height := 3.0
@export var crouch_camera_height := 2.0
@export var normal_height := 1.5
@export var crouch_height := 1.0
@export var crouch_lerp_speed := 10.0

@export_category("Camera")
@export var normal_fov := 70.0
@export var sprint_fov := 80.0
@export var crouch_fov := 65.0
@export var camera_lerp_speed := 10.0

@onready var camera: Camera3D = $Camera3D
@onready var body_collision: CollisionShape3D = $Character
@onready var head_collision: CollisionShape3D = $Head
@onready var animation_player: AnimationPlayer = $Animation

@onready var capsule: CapsuleShape3D = body_collision.shape

var step_player: AudioStreamPlayer

var current_speed := 0.0
var target_fov := 70.0

var is_crouching := false
var is_sprinting := false
var is_jumping := false

var step_timer := 0.0
var step_interval := 1.0

enum Anim {
	IDLE, WALK, RUN, JUMP, CROUCH, CROUCH_WALK
}

const ANIMS := {
	Anim.IDLE: "Animation/Idle",
	Anim.WALK: "Animation/Walk",
	Anim.RUN: "Animation/Run",
	Anim.JUMP: "Animation/Jump",
	Anim.CROUCH: "Animation/Crouch",
	Anim.CROUCH_WALK: "Animation/Crouch_Walk"
}

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	current_speed = walk_speed
	target_fov = normal_fov
	camera.position.y = stand_camera_height

	for node in get_tree().get_nodes_in_group("Sound"):
		if node is AudioStreamPlayer and node.name == "Step":
			step_player = node
			break

	if not SaveManager.loaded_player_data.is_empty():
		position = SaveManager.loaded_player_data.get("position", position)
		rotation.y = SaveManager.loaded_player_data.get("rotation_y", rotation.y)
		SaveManager.clear_loaded_data()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var rel: Vector2 = Vector2(event.relative) * mouse_sensitivity
		rotate_y(-rel.x)
		camera.rotation.x = clamp(
			camera.rotation.x - rel.y,
			deg_to_rad(min_pitch_deg),
			deg_to_rad(max_pitch_deg)
		)

func _physics_process(delta: float) -> void:
	var input_vec := Input.get_vector("left", "right", "up", "down")

	_update_state(input_vec)
	_apply_gravity(delta)
	_handle_jump()
	_handle_movement(input_vec, delta)
	_update_crouch(delta)
	_update_camera(delta)
	_update_animation(input_vec)
	_handle_footsteps(delta)

	move_and_slide()

func _update_state(input_vec: Vector2) -> void:
	is_crouching = Input.is_action_pressed("crouch")
	is_sprinting = Input.is_action_pressed("sprint") \
		and not is_crouching \
		and is_on_floor() \
		and input_vec.y < 0

	current_speed = (
		sprint_speed if is_sprinting
		else crouch_speed if is_crouching
		else walk_speed
	)

	target_fov = (
		sprint_fov if is_sprinting
		else crouch_fov if is_crouching
		else normal_fov
	)

func _handle_movement(input_vec: Vector2, delta: float) -> void:
	var direction := Vector3.ZERO
	if input_vec.length() > 0:
		direction = (
			transform.basis.z * input_vec.y +
			transform.basis.x * input_vec.x
		).normalized()

	if is_on_floor():
		var lerp_speed := acceleration if direction.length() > 0 else deceleration
		velocity.x = lerp(velocity.x, direction.x * current_speed, lerp_speed * delta)
		velocity.z = lerp(velocity.z, direction.z * current_speed, lerp_speed * delta)

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		is_jumping = false
		velocity.y = 0.0

func _handle_jump() -> void:
	if Input.is_action_just_pressed("ui_accept") and is_on_floor() and not is_crouching:
		is_jumping = true
		velocity.y = jump_velocity
		_play_anim(ANIMS[Anim.JUMP])

func _update_crouch(delta: float) -> void:
	var target_height := crouch_height if is_crouching else normal_height
	capsule.height = lerp(capsule.height, target_height, crouch_lerp_speed * delta)

	var cam_h := crouch_camera_height if is_crouching else stand_camera_height
	camera.position.y = lerp(camera.position.y, cam_h, crouch_lerp_speed * delta)

	if head_collision:
		head_collision.disabled = is_crouching

func _update_camera(delta: float) -> void:
	camera.fov = lerp(camera.fov, target_fov, camera_lerp_speed * delta)

func _update_animation(input_vec: Vector2) -> void:
	_play_anim(_get_desired_anim(input_vec))

func _get_desired_anim(input_vec: Vector2) -> String:
	if is_jumping:
		return ANIMS[Anim.JUMP]

	if is_crouching:
		return ANIMS[Anim.CROUCH_WALK] if input_vec.length() > 0 else ANIMS[Anim.CROUCH]

	if input_vec.length() > 0:
		return ANIMS[Anim.RUN] if is_sprinting else ANIMS[Anim.WALK]

	return ANIMS[Anim.IDLE]

func _play_anim(anim_name: String) -> void:
	if animation_player.current_animation != anim_name:
		animation_player.play(anim_name, 0.2)

func _handle_footsteps(delta: float) -> void:
	if not is_on_floor() or is_crouching:
		return

	if Vector2(velocity.x, velocity.z).length() < 0.1:
		return

	step_timer -= delta
	if step_timer <= 0.0 and step_player:
		step_player.pitch_scale = randf_range(0.85, 1.15)
		step_player.play()
		step_timer = step_interval / (current_speed / walk_speed)

func save_position() -> void:
	SaveManager.save_game(position, rotation.y)
