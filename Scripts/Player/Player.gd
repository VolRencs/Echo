extends CharacterBody3D

@export var mouse_sensitivity: float = 0.0015
@export var max_pitch_deg: float = 80.0
@export var min_pitch_deg: float = -60.0

@export var walk_speed: float = 5.0
@export var sprint_speed: float = 8.0
@export var crouch_speed: float = 2.5
@export var acceleration: float = 15.0
@export var deceleration: float = 20.0

@export var jump_velocity: float = 4.5
@export var gravity: float = 12.5

@export var stand_camera_height: float = 3.2
@export var crouch_camera_height: float = 2.0
@export var normal_height: float = 1.0
@export var crouch_height: float = 1.0
@export var camera_smooth_speed: float = 10.0

@export var sprint_fov: float = 80.0
@export var normal_fov: float = 70.0
@export var crouch_fov: float = 65.0

@onready var camera: Camera3D = $Camera3D
@onready var body_collision: CollisionShape3D = $Character
@onready var head_collision: CollisionShape3D = $Head
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var inventory: Control = $"../Inventory"

var anim_states := {
	"jump": "Jump",
	"walk": "Walk",
	"run": "Running",
	"crouch_walk": "Crouch_Walk",
	"idle": "Idle",
	"crouch_idle": "Crouch_Idle"
}

var step_player: AudioStreamPlayer = null
var current_speed: float
var target_fov: float
var is_crouching: bool = false
var is_sprinting: bool = false
var is_jumping: bool = false
var rotation_y: float = 0.0
var step_timer: float = 0.0
var step_interval: float = 1.0
var camera_offset: float

func get_max_pitch() -> float:
	return deg_to_rad(max_pitch_deg)

func get_min_pitch() -> float:
	return deg_to_rad(min_pitch_deg)

func _ready() -> void:
	current_speed = walk_speed
	target_fov = normal_fov
	camera_offset = stand_camera_height
	camera.position.y = camera_offset
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

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
		var rel: Vector2 = event.relative * mouse_sensitivity
		rotate_y(-rel.x)
		camera.rotation.x = clamp(camera.rotation.x - rel.y, get_min_pitch(), get_max_pitch())

func _physics_process(delta: float) -> void:
	velocity.y -= gravity * delta
	if is_on_floor() and velocity.y <= 0.0:
		is_jumping = false
		velocity.y = 0.0

	var input_vec: Vector2 = Input.get_vector("left", "right", "up", "down")
	var crouch_pressed: bool = Input.is_action_pressed("crouch")
	var sprint_pressed: bool = Input.is_action_pressed("sprint")

	_update_crouch(crouch_pressed, delta)
	_update_movement_state(input_vec, crouch_pressed, sprint_pressed)

	var direction: Vector3 = Vector3.ZERO
	if input_vec.length() > 0:
		direction = (transform.basis.z * input_vec.y + transform.basis.x * input_vec.x).normalized()

	var desired_anim: String = anim_states["jump"] if is_jumping else \
		anim_states["crouch_walk"] if input_vec.length() > 0 and is_crouching else \
		anim_states["run"] if input_vec.length() > 0 and is_sprinting else \
		anim_states["walk"] if input_vec.length() > 0 else \
		anim_states["crouch_idle"] if is_crouching else \
		anim_states["idle"]
	_play_anim(desired_anim)

	if is_on_floor():
		var lerp_speed: float = acceleration if direction.length() > 0 else deceleration
		velocity.x = lerp(velocity.x, direction.x * current_speed, lerp_speed * delta)
		velocity.z = lerp(velocity.z, direction.z * current_speed, lerp_speed * delta)

	if Input.is_action_just_pressed("ui_accept") and is_on_floor() and not is_crouching:
		is_jumping = true
		velocity.y = jump_velocity
		_play_anim(anim_states["jump"])

	camera.fov = lerp(camera.fov, target_fov, camera_smooth_speed * delta)

	if is_on_floor() and not is_crouching and Vector2(velocity.x, velocity.z).length() > 0.1:
		step_timer -= delta
		if step_timer <= 0.0 and step_player:
			step_player.pitch_scale = randf_range(0.8, 1.2)
			step_player.play()
			step_timer = step_interval / (current_speed / walk_speed)

	move_and_slide()

func _play_anim(anim_name: String) -> void:
	if animation_player and animation_player.current_animation != anim_name:
		animation_player.play(anim_name, 0.2)

func _update_crouch(crouch: bool, delta: float) -> void:
	is_crouching = crouch
	var capsule: CapsuleShape3D = body_collision.shape as CapsuleShape3D
	var target_height: float = normal_height if not crouch else crouch_height
	capsule.height = lerp(capsule.height, target_height, 10.0 * delta)

	var target_cam_h := stand_camera_height if not crouch else crouch_camera_height
	camera.position.y = lerp(camera.position.y, target_cam_h, 10.0 * delta)
	if head_collision:
		head_collision.disabled = crouch

func _update_movement_state(input_vec: Vector2, crouch: bool, sprint: bool) -> void:
	is_crouching = crouch
	is_sprinting = sprint and not is_crouching and is_on_floor() and input_vec.y < 0
	current_speed = sprint_speed if is_sprinting else (crouch_speed if is_crouching else walk_speed)
	target_fov = sprint_fov if is_sprinting else (crouch_fov if is_crouching else normal_fov)

func save_position() -> void:
	SaveManager.save_game(position, rotation.y)
