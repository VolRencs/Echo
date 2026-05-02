extends CharacterBody3D

# ─── EXPORTS ──────────────────────────────────────────────────────────────────

@export_category("Mouse")
@export var mouse_sensitivity  := 0.0015
@export var max_pitch_deg      := 80.0
@export var min_pitch_deg      := -60.0

@export_category("Movement")
@export var walk_speed         := 5.0
@export var sprint_speed       := 8.0
@export var sneak_speed        := 1.5
@export var acceleration       := 15.0
@export var deceleration       := 20.0
@export_range(0.0, 1.0, 0.01) var air_control := 0.15

@export_category("Gravity")
@export var gravity            := 12.5

@export_category("Sneak")
@export var sneak_lean_deg     := 8.0
@export var sneak_lean_speed   := 6.0

@export_category("Stamina")
@export var max_stamina            := 100.0
@export var stamina_drain_sprint   := 20.0
@export var stamina_regen_rate     := 10.0
@export var stamina_regen_delay    := 1.5

@export_category("Footsteps")
@export var step_interval      := 0.5

@export_category("Camera")
@export var normal_fov           := 70.0
@export var sprint_fov           := 80.0
@export var sneak_fov            := 67.0
@export var camera_lerp_speed    := 10.0
@export var camera_smoothing     := 10.0
@export var head_sway_amount     := 0.05
@export var head_sway_speed      := 5.0
@export var stand_camera_height  := 3.0
@export var camera_height_offset := 0.35
@export var head_bone_name       := "mixamorig_Head"

# ─── CONSTANTS ────────────────────────────────────────────────────────────────

const INPUT_DEADZONE_SQ     := 0.01
const FOOTSTEP_SPEED_SQ     := 0.01
const HEAD_BOB_MIN_SPEED_SQ := 0.01
const VELOCITY_SMOOTHING    := 10.0
const CAMERA_FOV_EPSILON    := 0.01
const CAMERA_ROT_EPSILON    := 0.001

const ANIM_IDLE   : StringName = &"Animation/Idle"
const ANIM_WALK   : StringName = &"Animation/Walk"
const ANIM_RUN    : StringName = &"Animation/Run"

# ─── NODES ────────────────────────────────────────────────────────────────────

@onready var camera:           Camera3D         = $Camera3D
@onready var body_collision:   CollisionShape3D = $Character
@onready var animation_player: AnimationPlayer  = $Animation
@onready var skeleton:         Skeleton3D       = $Skeleton3D
@onready var capsule:          CapsuleShape3D   = body_collision.shape

# ─── STATE ────────────────────────────────────────────────────────────────────

var _step_player:     AudioStreamPlayer

var _current_speed:   float   = 0.0
var _target_fov:      float   = 0.0
var _step_timer:      float   = 0.0

var is_sneaking:      bool    = false
var is_sprinting:     bool    = false

var _pitch:           float   = 0.0
var _max_pitch_rad:   float
var _min_pitch_rad:   float

var _sneak_lean:      float   = 0.0

var _head_bob_time:   float   = 0.0
var _head_bob_blend:  float   = 0.0
var _velocity_smooth: Vector3 = Vector3.ZERO
var _head_bone_idx:   int     = -1

# Stamina
var _stamina:             float = 0.0
var _stamina_regen_timer: float = 0.0
var _stamina_exhausted:   bool  = false

# ─── READY ────────────────────────────────────────────────────────────────────

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	_max_pitch_rad = deg_to_rad(max_pitch_deg)
	_min_pitch_rad = deg_to_rad(min_pitch_deg)
	_target_fov    = normal_fov
	_current_speed = walk_speed
	_step_timer    = step_interval
	_stamina       = max_stamina

	camera.position.y = stand_camera_height

	_step_player = NodeUtils.find_audio_stream_player(get_tree(), &"Step")

	_load_saved_position()
	call_deferred("_init_head_bone")

# ─── INIT ─────────────────────────────────────────────────────────────────────

func _init_head_bone() -> void:
	if not skeleton:
		push_warning("PlayerController: Skeleton3D not found — camera will use fixed height.")
		return
	await get_tree().process_frame
	_head_bone_idx = skeleton.find_bone(head_bone_name)
	if _head_bone_idx == -1:
		push_warning("PlayerController: bone '%s' not found in skeleton." % head_bone_name)

func _load_saved_position() -> void:
	if SaveManager.loaded_player_data.is_empty():
		return
	position   = SaveManager.loaded_player_data.get("position",   position)
	rotation.y = SaveManager.loaded_player_data.get("rotation_y", rotation.y)
	SaveManager.clear_loaded_data()

# ─── INPUT ────────────────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var rel: Vector2 = (event as InputEventMouseMotion).relative * mouse_sensitivity
		rotate_y(-rel.x)
		_pitch = clamp(_pitch - rel.y, _min_pitch_rad, _max_pitch_rad)

# ─── PHYSICS ──────────────────────────────────────────────────────────────────

func _physics_process(delta: float) -> void:
	var input_vec := Input.get_vector("left", "right", "up", "down")
	var moving    := input_vec.length_squared() > INPUT_DEADZONE_SQ
	var on_floor  := is_on_floor()

	_update_state(input_vec, moving, on_floor)
	_update_stamina(delta)
	_apply_gravity(delta, on_floor)
	_handle_movement(input_vec, moving, delta, on_floor)
	_update_camera(delta, on_floor)
	_play_anim(_get_anim_name(moving, on_floor))
	_handle_footsteps(delta, on_floor)

	move_and_slide()

# ─── STATE ────────────────────────────────────────────────────────────────────

func _update_state(input_vec: Vector2, moving: bool, on_floor: bool) -> void:
	# ── Sneak ───────────────────────────────────────────────────────────────
	is_sneaking = Input.is_action_pressed("crouch") and on_floor

	# ── Sprint (снкинг блокирует спринт) ────────────────────────────────────
	is_sprinting = (
		moving
		and Input.is_action_pressed("sprint")
		and not is_sneaking
		and on_floor
		and input_vec.y < 0.0
		and not _stamina_exhausted
	)

	# ── Speed & FOV ─────────────────────────────────────────────────────────
	if is_sprinting:
		_current_speed = sprint_speed
		_target_fov    = sprint_fov
	elif is_sneaking:
		_current_speed = sneak_speed
		_target_fov    = sneak_fov
	else:
		_current_speed = walk_speed
		_target_fov    = normal_fov

# ─── STAMINA ──────────────────────────────────────────────────────────────────

func _update_stamina(delta: float) -> void:
	if is_sprinting:
		_stamina             = maxf(_stamina - stamina_drain_sprint * delta, 0.0)
		_stamina_regen_timer = stamina_regen_delay

		if _stamina <= 0.0:
			_stamina_exhausted = true
	else:
		if _stamina_regen_timer > 0.0:
			_stamina_regen_timer -= delta
		else:
			_stamina = minf(_stamina + stamina_regen_rate * delta, max_stamina)

			if _stamina_exhausted and _stamina >= max_stamina:
				_stamina_exhausted = false

func get_stamina_normalized() -> float:
	return _stamina / max_stamina

# ─── GRAVITY ──────────────────────────────────────────────────────────────────

func _apply_gravity(delta: float, on_floor: bool) -> void:
	if on_floor and velocity.y < 0.0:
		velocity.y = 0.0
	elif not on_floor:
		velocity.y -= gravity * delta

# ─── MOVEMENT ─────────────────────────────────────────────────────────────────

func _handle_movement(input_vec: Vector2, moving: bool, delta: float, on_floor: bool) -> void:
	var target_vel := Vector3.ZERO
	if moving:
		target_vel = (
			transform.basis.z * input_vec.y +
			transform.basis.x * input_vec.x
		).normalized() * _current_speed

	var control := 1.0 if on_floor else air_control
	var accel_t := (deceleration if target_vel.is_zero_approx() else acceleration) * control * delta

	velocity.x = lerpf(velocity.x, target_vel.x, accel_t)
	velocity.z = lerpf(velocity.z, target_vel.z, accel_t)

# ─── CAMERA ───────────────────────────────────────────────────────────────────

func _update_camera(delta: float, on_floor: bool) -> void:
	var bob := _calc_head_bob(delta, on_floor)

	var target_lean := deg_to_rad(sneak_lean_deg) if is_sneaking else 0.0
	_sneak_lean = lerpf(_sneak_lean, target_lean, sneak_lean_speed * delta)

	if _head_bone_idx != -1:
		var head_local  := _head_world_to_local()
		head_local.y    += camera_height_offset
		camera.position  = head_local + bob
	else:
		var target_pos := Vector3(0.0, stand_camera_height + camera_height_offset, 0.0) + bob
		camera.position = camera.position.lerp(target_pos, camera_smoothing * delta)

	if absf(camera.fov - _target_fov) > CAMERA_FOV_EPSILON:
		camera.fov = lerpf(camera.fov, _target_fov, camera_lerp_speed * delta)
	else:
		camera.fov = _target_fov

	var desired_pitch := _pitch + _sneak_lean
	if absf(camera.rotation.x - desired_pitch) > CAMERA_ROT_EPSILON:
		camera.rotation.x = lerp_angle(camera.rotation.x, desired_pitch, camera_smoothing * delta)
	else:
		camera.rotation.x = desired_pitch

func _head_world_to_local() -> Vector3:
	var pose := skeleton.get_bone_global_pose(_head_bone_idx)
	return to_local(skeleton.global_transform * pose.origin)

func _calc_head_bob(delta: float, on_floor: bool) -> Vector3:
	if not on_floor:
		_head_bob_blend = 0.0
		return Vector3.ZERO

	_velocity_smooth = _velocity_smooth.lerp(velocity, VELOCITY_SMOOTHING * delta)
	var h_speed_sq := _velocity_smooth.x * _velocity_smooth.x + _velocity_smooth.z * _velocity_smooth.z
	var is_moving  := h_speed_sq >= HEAD_BOB_MIN_SPEED_SQ

	_head_bob_blend = lerpf(_head_bob_blend, 1.0 if is_moving else 0.0, head_sway_speed * delta)

	if is_moving:
		_head_bob_time = fmod(
			_head_bob_time + delta * head_sway_speed * (sqrt(h_speed_sq) / walk_speed),
			TAU
		)

	if is_zero_approx(_head_bob_blend):
		return Vector3.ZERO

	return Vector3(
		sin(_head_bob_time)            * head_sway_amount       * _head_bob_blend,
		abs(sin(_head_bob_time * 2.0)) * head_sway_amount * 0.5 * _head_bob_blend,
		0.0
	)

# ─── ANIMATION ────────────────────────────────────────────────────────────────

func _get_anim_name(moving: bool, _on_floor: bool) -> StringName:
	if is_sprinting: return ANIM_RUN
	if moving:       return ANIM_WALK
	return ANIM_IDLE

func _play_anim(anim_name: StringName) -> void:
	if animation_player.current_animation != anim_name:
		animation_player.play(anim_name, 0.2)

# ─── FOOTSTEPS ────────────────────────────────────────────────────────────────

func _handle_footsteps(delta: float, on_floor: bool) -> void:
	if not _step_player or not on_floor or is_sneaking:
		_step_timer = step_interval
		return

	if velocity.x * velocity.x + velocity.z * velocity.z < FOOTSTEP_SPEED_SQ:
		return

	_step_timer -= delta
	if _step_timer <= 0.0:
		_step_player.pitch_scale = randf_range(0.85, 1.15)
		_step_player.play()
		_step_timer = step_interval / (_current_speed / walk_speed)

# ─── SAVE ─────────────────────────────────────────────────────────────────────

func save_position() -> void:
	SaveManager.save_game(position, rotation.y)
