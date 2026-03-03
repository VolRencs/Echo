extends CharacterBody3D

# ─── EXPORTS ──────────────────────────────────────────────────────────────────

@export_category("Mouse")
@export var mouse_sensitivity := 0.0015
@export var max_pitch_deg    := 80.0
@export var min_pitch_deg    := -60.0

@export_category("Movement")
@export var walk_speed   := 5.0
@export var sprint_speed := 8.0
@export var crouch_speed := 2.5
@export var acceleration := 15.0
@export var deceleration := 20.0

@export_category("Jump & Gravity")
@export var jump_velocity := 4.5
@export var gravity       := 12.5

@export_category("Crouch")
@export var stand_camera_height  := 3.0
@export var crouch_camera_height := 2.0
@export var normal_height        := 1.1
@export var crouch_height        := 1.0
@export var crouch_lerp_speed    := 10.0

@export_category("Footsteps")
@export var step_interval := 0.5

@export_category("Camera")
@export var normal_fov           := 70.0
@export var sprint_fov           := 80.0
@export var crouch_fov           := 65.0
@export var camera_lerp_speed    := 10.0
@export var camera_smoothing     := 10.0
@export var head_sway_amount     := 0.05
@export var head_sway_speed      := 5.0
@export var camera_height_offset := 0.35
@export var head_bone_name       := "mixamorig_Head"

# ─── NODES ────────────────────────────────────────────────────────────────────

@onready var camera:           Camera3D         = $Camera3D
@onready var body_collision:   CollisionShape3D = $Character
@onready var head_collision:   CollisionShape3D = $Head
@onready var animation_player: AnimationPlayer  = $Animation
@onready var skeleton:         Skeleton3D       = $Skeleton3D
@onready var capsule:          CapsuleShape3D   = body_collision.shape

# ─── ANIMATION MAP ────────────────────────────────────────────────────────────

enum Anim { IDLE, WALK, RUN, JUMP, CROUCH, CROUCH_WALK }

const ANIMS := {
	Anim.IDLE:        "Animation/Idle",
	Anim.WALK:        "Animation/Walk",
	Anim.RUN:         "Animation/Run",
	Anim.JUMP:        "Animation/Jump",
	Anim.CROUCH:      "Animation/Crouch",
	Anim.CROUCH_WALK: "Animation/Crouch_Walk",
}

# ─── STATE ────────────────────────────────────────────────────────────────────

var _step_player:        AudioStreamPlayer
var _current_speed:      float   = walk_speed
var _target_fov:         float   = 0.0
var _step_timer:         float   = 0.0

var is_crouching: bool = false
var is_sprinting: bool = false

var _max_pitch_rad:      float
var _min_pitch_rad:      float
var _pitch:              float   = 0.0
var _head_bob_time:      float   = 0.0
var _velocity_smooth:    Vector3 = Vector3.ZERO
var _head_bone_idx:      int     = -1
var _cam_base_local_pos: Vector3

# ─── READY ────────────────────────────────────────────────────────────────────

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	_max_pitch_rad = deg_to_rad(max_pitch_deg)
	_min_pitch_rad = deg_to_rad(min_pitch_deg)
	_target_fov    = normal_fov

	camera.position.y   = stand_camera_height
	_cam_base_local_pos = camera.position

	for node in get_tree().get_nodes_in_group("Sound"):
		if node.name == "Step" and node is AudioStreamPlayer:
			_step_player = node
			break

	_load_saved_position()
	call_deferred("_init_head_bone")

# ─── INIT ─────────────────────────────────────────────────────────────────────

func _init_head_bone() -> void:
	if not skeleton:
		push_warning("PlayerController: Skeleton3D not found — camera will not track head bone.")
		return
	await get_tree().process_frame
	_head_bone_idx = skeleton.find_bone(head_bone_name)
	if _head_bone_idx == -1:
		push_warning("PlayerController: bone '%s' not found in skeleton." % head_bone_name)
		return
	_cam_base_local_pos = _head_world_to_local()

func _load_saved_position() -> void:
	if SaveManager.loaded_player_data.is_empty():
		return
	position   = SaveManager.loaded_player_data.get("position",   position)
	rotation.y = SaveManager.loaded_player_data.get("rotation_y", rotation.y)
	SaveManager.clear_loaded_data()

# ─── INPUT ────────────────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var rel: Vector2 = event.relative * mouse_sensitivity
		rotate_y(-rel.x)
		_pitch = clamp(_pitch - rel.y, _min_pitch_rad, _max_pitch_rad)

# ─── PHYSICS ──────────────────────────────────────────────────────────────────

func _physics_process(delta: float) -> void:
	var input_vec := Input.get_vector("left", "right", "up", "down")

	_update_state(input_vec)
	_apply_gravity(delta)
	_handle_jump()
	_handle_movement(input_vec, delta)
	_update_crouch(delta)
	_update_camera(delta)
	_play_anim(ANIMS[_get_anim(input_vec)])
	_handle_footsteps(delta)

	move_and_slide()

# ─── STATE ────────────────────────────────────────────────────────────────────

func _update_state(input_vec: Vector2) -> void:
	is_crouching = Input.is_action_pressed("crouch")
	is_sprinting = (
		Input.is_action_pressed("sprint")
		and not is_crouching
		and is_on_floor()
		and input_vec.y < 0.0
	)

	match true:
		is_sprinting: _current_speed = sprint_speed; _target_fov = sprint_fov
		is_crouching: _current_speed = crouch_speed; _target_fov = crouch_fov
		_:            _current_speed = walk_speed;   _target_fov = normal_fov

# ─── MOVEMENT ─────────────────────────────────────────────────────────────────

func _handle_movement(input_vec: Vector2, delta: float) -> void:
	if not is_on_floor():
		return

	var target_vel := Vector3.ZERO
	if input_vec.length_squared() > 0.01:
		target_vel = (
			transform.basis.z * input_vec.y +
			transform.basis.x * input_vec.x
		).normalized() * _current_speed

	var t := (deceleration if target_vel.is_zero_approx() else acceleration) * delta
	velocity.x = lerp(velocity.x, target_vel.x, t)
	velocity.z = lerp(velocity.z, target_vel.z, t)

func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= gravity * delta

func _handle_jump() -> void:
	if Input.is_action_just_pressed("ui_accept") and is_on_floor() and not is_crouching:
		velocity.y = jump_velocity

# ─── CROUCH ───────────────────────────────────────────────────────────────────

func _update_crouch(delta: float) -> void:
	capsule.height = lerp(
		capsule.height,
		crouch_height if is_crouching else normal_height,
		crouch_lerp_speed * delta
	)
	if head_collision:
		head_collision.disabled = is_crouching

# ─── CAMERA ───────────────────────────────────────────────────────────────────

func _update_camera(delta: float) -> void:
	# Если кость не нашлась — фолбэк на фиксированную высоту
	_cam_base_local_pos = (
		_head_world_to_local() if _head_bone_idx != -1
		else Vector3(0.0, crouch_camera_height if is_crouching else stand_camera_height, 0.0)
	)
	_cam_base_local_pos.y += camera_height_offset

	camera.position   = _cam_base_local_pos + _calc_head_bob(delta)
	camera.fov        = lerp(camera.fov, _target_fov, camera_lerp_speed * delta)
	camera.rotation.x = lerp_angle(camera.rotation.x, _pitch, camera_smoothing * delta)

func _head_world_to_local() -> Vector3:
	var pose := skeleton.get_bone_global_pose(_head_bone_idx)
	return to_local(skeleton.global_transform * pose.origin)

func _calc_head_bob(delta: float) -> Vector3:
	if not is_on_floor():
		return Vector3.ZERO

	_velocity_smooth = _velocity_smooth.lerp(velocity, delta * 10.0)
	var h_speed := Vector2(_velocity_smooth.x, _velocity_smooth.z).length()

	if h_speed < 0.1:
		_head_bob_time = 0.0
		return Vector3.ZERO

	_head_bob_time += delta * head_sway_speed * (h_speed / walk_speed)
	return Vector3(
		sin(_head_bob_time)            * head_sway_amount,
		abs(sin(_head_bob_time * 2.0)) * head_sway_amount * 0.5,
		0.0
	)

# ─── ANIMATION ────────────────────────────────────────────────────────────────

func _get_anim(input_vec: Vector2) -> Anim:
	if not is_on_floor(): return Anim.JUMP

	var moving := input_vec.length_squared() > 0.01
	if is_crouching: return Anim.CROUCH_WALK if moving else Anim.CROUCH
	if moving:       return Anim.RUN         if is_sprinting else Anim.WALK
	return Anim.IDLE

func _play_anim(anim_name: String) -> void:
	if animation_player.current_animation != anim_name:
		animation_player.play(anim_name, 0.2)

# ─── FOOTSTEPS ────────────────────────────────────────────────────────────────

func _handle_footsteps(delta: float) -> void:
	if not _step_player or not is_on_floor() or is_crouching:
		return
	if velocity.x * velocity.x + velocity.z * velocity.z < 0.01:
		return

	_step_timer -= delta
	if _step_timer <= 0.0:
		_step_player.pitch_scale = randf_range(0.85, 1.15)
		_step_player.play()
		_step_timer = step_interval / (_current_speed / walk_speed)

# ─── SAVE ─────────────────────────────────────────────────────────────────────

func save_position() -> void:
	SaveManager.save_game(position, rotation.y)
