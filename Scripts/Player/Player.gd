extends CharacterBody3D

# ─── EXPORTS ──────────────────────────────────────────────────────────────────

@export_category("Mouse")
@export var mouse_sensitivity  := 0.0015
@export var max_pitch_deg      := 80.0
@export var min_pitch_deg      := -60.0

@export_category("Movement")
@export var walk_speed         := 5.0
@export var sprint_speed       := 8.0
@export var crouch_speed       := 2.5
@export var acceleration       := 15.0
@export var deceleration       := 20.0
@export_range(0.0, 1.0, 0.01) var air_control := 0.15

@export_category("Gravity")
@export var gravity            := 12.5

@export_category("Crouch")
@export var stand_camera_height  := 3.0
@export var crouch_camera_height := 2.0
@export var normal_height        := 1.1
@export var crouch_height        := 1.0
@export var crouch_lerp_speed    := 4.0
@export var crouch_cooldown      := 0.4
@export var crouch_wall_clearance := 0.15

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
@export var crouch_fov           := 65.0
@export var camera_lerp_speed    := 10.0
@export var camera_smoothing     := 10.0
@export var head_sway_amount     := 0.05
@export var head_sway_speed      := 5.0
@export var camera_height_offset := 0.35
@export var head_bone_name       := "mixamorig_Head"

# ─── CONSTANTS ────────────────────────────────────────────────────────────────

const INPUT_DEADZONE_SQ     := 0.01
const FOOTSTEP_SPEED_SQ     := 0.01
const HEAD_BOB_MIN_SPEED_SQ := 0.01
const VELOCITY_SMOOTHING    := 10.0
const CAMERA_FOV_EPSILON    := 0.01
const CAMERA_ROT_EPSILON    := 0.001

const ANIM_IDLE        : StringName = &"Animation/Idle"
const ANIM_WALK        : StringName = &"Animation/Walk"
const ANIM_RUN         : StringName = &"Animation/Run"
const ANIM_JUMP        : StringName = &"Animation/Jump"
const ANIM_CROUCH      : StringName = &"Animation/Crouch"
const ANIM_CROUCH_WALK : StringName = &"Animation/Crouch_Walk"

# ─── NODES ────────────────────────────────────────────────────────────────────

@onready var camera:           Camera3D         = $Camera3D
@onready var body_collision:   CollisionShape3D = $Character
@onready var head_collision:   CollisionShape3D = $Head
@onready var animation_player: AnimationPlayer  = $Animation
@onready var skeleton:         Skeleton3D       = $Skeleton3D
@onready var capsule:          CapsuleShape3D   = body_collision.shape

# ─── STATE ────────────────────────────────────────────────────────────────────

var _step_player:     AudioStreamPlayer

var _current_speed:   float   = 0.0
var _target_fov:      float   = 0.0
var _step_timer:      float   = 0.0

var is_crouching:     bool    = false
var is_sprinting:     bool    = false

var _pitch:           float   = 0.0
var _max_pitch_rad:   float
var _min_pitch_rad:   float

var _head_bob_time:   float   = 0.0
var _head_bob_blend:  float   = 0.0
var _velocity_smooth: Vector3 = Vector3.ZERO
var _head_bone_idx:   int     = -1

# Stamina
var _stamina:             float = 0.0
var _stamina_regen_timer: float = 0.0
# Флаг истощения: true когда стамина дошла до 0.
# Бег заблокирован пока стамина не восстановится до максимума.
var _stamina_exhausted:   bool  = false

var _crouch_cooldown_timer: float = 0.0

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

	_crouch_cooldown_timer = maxf(_crouch_cooldown_timer - delta, 0.0)

	_update_state(input_vec, moving, on_floor)
	_update_stamina(delta)
	_apply_gravity(delta, on_floor)
	_handle_movement(input_vec, moving, delta, on_floor)
	_update_crouch(delta)
	_update_camera(delta, on_floor)
	_play_anim(_get_anim_name(moving, on_floor))
	_handle_footsteps(delta, on_floor)

	move_and_slide()

# ─── STATE ────────────────────────────────────────────────────────────────────

func _update_state(input_vec: Vector2, moving: bool, on_floor: bool) -> void:
	# ── Crouch ──────────────────────────────────────────────────────────────
	var wants_crouch := Input.is_action_pressed("crouch")

	if _crouch_cooldown_timer > 0.0:
		wants_crouch = is_crouching

	var wall_too_close := _is_wall_nearby()
	if wall_too_close:
		wants_crouch = false

	var new_crouch := wants_crouch or (is_crouching and _is_ceiling_blocked())

	if new_crouch != is_crouching:
		if not wall_too_close:
			_crouch_cooldown_timer = crouch_cooldown

	is_crouching = new_crouch

	# ── Sprint ──────────────────────────────────────────────────────────────
	is_sprinting = (
		moving
		and Input.is_action_pressed("sprint")
		and not is_crouching
		and on_floor
		and input_vec.y < 0.0
		and not _stamina_exhausted   # заблокировано до полного восстановления
	)

	# ── Speed & FOV ─────────────────────────────────────────────────────────
	if is_sprinting:
		_current_speed = sprint_speed
		_target_fov    = sprint_fov
	elif is_crouching:
		_current_speed = crouch_speed
		_target_fov    = crouch_fov
	else:
		_current_speed = walk_speed
		_target_fov    = normal_fov

# ─── WALL / CEILING CHECK ─────────────────────────────────────────────────────

func _is_ceiling_blocked() -> bool:
	var ray_from := global_position + Vector3.UP * (crouch_height * 0.5)
	var ray_to   := global_position + Vector3.UP * (normal_height * 0.5 + 0.05)
	var query    := PhysicsRayQueryParameters3D.create(ray_from, ray_to)
	query.exclude = [self]
	return not get_world_3d().direct_space_state.intersect_ray(query).is_empty()

func _is_wall_nearby() -> bool:
	var space := get_world_3d().direct_space_state

	var check_shape        := CapsuleShape3D.new()
	check_shape.radius     = capsule.radius + crouch_wall_clearance
	check_shape.height     = crouch_height

	var params             := PhysicsShapeQueryParameters3D.new()
	params.shape           = check_shape
	params.transform       = body_collision.global_transform
	params.exclude         = [get_rid()]
	params.collision_mask  = collision_mask

	return not space.intersect_shape(params, 1).is_empty()

# ─── STAMINA ──────────────────────────────────────────────────────────────────

func _update_stamina(delta: float) -> void:
	if is_sprinting:
		_stamina             = maxf(_stamina - stamina_drain_sprint * delta, 0.0)
		_stamina_regen_timer = stamina_regen_delay

		# Стамина только что кончилась — включаем флаг истощения
		if _stamina <= 0.0:
			_stamina_exhausted = true
	else:
		if _stamina_regen_timer > 0.0:
			_stamina_regen_timer -= delta
		else:
			_stamina = minf(_stamina + stamina_regen_rate * delta, max_stamina)

			# Снимаем флаг истощения только при полном восстановлении
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

# ─── CROUCH ───────────────────────────────────────────────────────────────────

func _update_crouch(delta: float) -> void:
	var target_height := crouch_height if is_crouching else normal_height
	if not is_equal_approx(capsule.height, target_height):
		capsule.height = lerpf(capsule.height, target_height, crouch_lerp_speed * delta)
		if absf(capsule.height - target_height) <= 0.001:
			capsule.height = target_height

	if head_collision and head_collision.disabled != is_crouching:
		head_collision.disabled = is_crouching

# ─── CAMERA ───────────────────────────────────────────────────────────────────

func _update_camera(delta: float, on_floor: bool) -> void:
	var bob := _calc_head_bob(delta, on_floor)

	if _head_bone_idx != -1:
		var head_local  := _head_world_to_local()
		head_local.y    += camera_height_offset
		camera.position  = head_local + bob
	else:
		var target_y   := crouch_camera_height if is_crouching else stand_camera_height
		var target_pos := Vector3(0.0, target_y + camera_height_offset, 0.0) + bob
		camera.position = camera.position.lerp(target_pos, camera_smoothing * delta)

	if absf(camera.fov - _target_fov) > CAMERA_FOV_EPSILON:
		camera.fov = lerpf(camera.fov, _target_fov, camera_lerp_speed * delta)
	else:
		camera.fov = _target_fov

	if absf(camera.rotation.x - _pitch) > CAMERA_ROT_EPSILON:
		camera.rotation.x = lerp_angle(camera.rotation.x, _pitch, camera_smoothing * delta)
	else:
		camera.rotation.x = _pitch

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

func _get_anim_name(moving: bool, on_floor: bool) -> StringName:
	if not on_floor:  return ANIM_JUMP
	if is_crouching:  return ANIM_CROUCH_WALK if moving else ANIM_CROUCH
	if is_sprinting:  return ANIM_RUN
	if moving:        return ANIM_WALK
	return ANIM_IDLE

func _play_anim(anim_name: StringName) -> void:
	if animation_player.current_animation != anim_name:
		animation_player.play(anim_name, 0.2)

# ─── FOOTSTEPS ────────────────────────────────────────────────────────────────

func _handle_footsteps(delta: float, on_floor: bool) -> void:
	if not _step_player or not on_floor or is_crouching:
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
