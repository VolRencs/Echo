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

# Анимации как словарь — удобно менять имена в одном месте
var anim_states := {
	"jump": "Jump",
	"walk": "Walk",
	"run": "Running",
	"crouch_walk": "Crouch_Walk",
	"idle": "Idle",
	"crouch_idle": "Crouch_Idle"
}

var step_player: AudioStreamPlayer = null

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

	for node in get_tree().get_nodes_in_group("Sound"):
		if node is AudioStreamPlayer and node.name == "Step":
			step_player = node
			break

	if not GameState.loaded_player_data.is_empty():
		position = GameState.loaded_player_data.get("position", position)
		rotation.y = GameState.loaded_player_data.get("rotation_y", rotation.y)
		GameState.clear_loaded_data()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		var rel: Vector2 = event.relative * MOUSE_SENSITIVITY
		rotate_y(-rel.x)
		rotation_y = clamp(rotation_y - rel.y, MIN_PITCH, MAX_PITCH)
		camera.rotation.x = rotation_y

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0
		is_jumping = false

	var input_vec: Vector2 = Input.get_vector("left", "right", "up", "down")
	var crouch_pressed: bool = Input.is_action_pressed("crouch")
	var sprint_pressed: bool = Input.is_action_pressed("sprint")

	_handle_crouching(delta, crouch_pressed)
	_handle_sprinting(input_vec, sprint_pressed)

	var direction: Vector3 = Vector3.ZERO
	if input_vec.length() > 0:
		direction = (transform.basis.z * input_vec.y + transform.basis.x * input_vec.x).normalized()

	var desired_anim: String = ""
	if is_jumping:
		desired_anim = anim_states["jump"]
	elif input_vec.length() > 0:
		if is_crouching:
			desired_anim = anim_states["crouch_walk"]
		elif is_sprinting:
			desired_anim = anim_states["run"]
		else:
			desired_anim = anim_states["walk"]
	else:
		desired_anim = anim_states["crouch_idle"] if is_crouching else anim_states["idle"]

	_play_anim(desired_anim)

	if is_on_floor():
		var lerp_speed: float = ACCELERATION if direction.length() > 0 else DECELERATION
		velocity.x = lerp(velocity.x, direction.x * current_speed, lerp_speed * delta)
		velocity.z = lerp(velocity.z, direction.z * current_speed, lerp_speed * delta)

	if Input.is_action_just_pressed("ui_accept") and is_on_floor() and not is_crouching:
		is_jumping = true
		velocity.y = JUMP_VELOCITY
		_play_anim(anim_states["jump"])

	camera.fov = lerp(camera.fov, target_fov, CAMERA_SMOOTH_SPEED * delta)

	var horizontal_velocity := Vector2(velocity.x, velocity.z).length()
	if horizontal_velocity > 0.1 and is_on_floor() and not is_crouching:
		step_timer -= delta
		if step_timer <= 0.0:
			if step_player:
				step_player.stop()
				step_player.pitch_scale = randf_range(0.8, 1.2)
				step_player.play()
			step_timer = step_interval / (current_speed / WALK_SPEED)
	else:
		step_timer = 0.0

	move_and_slide()

func _play_anim(anim_name: String) -> void:
	if animation_player and animation_player.current_animation != anim_name:
		animation_player.play(anim_name, 0.2)

func _handle_crouching(delta: float, crouch_pressed: bool) -> void:
	var target_height: float = CROUCH_HEIGHT if crouch_pressed else NORMAL_HEIGHT
	var capsule: CapsuleShape3D = collision_shape.shape as CapsuleShape3D
	capsule.height = lerp(capsule.height, target_height, 10.0 * delta)

	camera_offset = CROUCH_CAMERA_HEIGHT if crouch_pressed else STAND_CAMERA_HEIGHT
	camera.position.y = lerp(camera.position.y, camera_offset, 10.0 * delta)

	if $Head:
		$Head.disabled = crouch_pressed

	is_crouching = crouch_pressed
	target_fov = CROUCH_FOV if is_crouching else NORMAL_FOV

func _handle_sprinting(input_vec: Vector2, sprint_pressed: bool) -> void:
	is_sprinting = sprint_pressed and is_on_floor() and not is_crouching and input_vec.y < 0
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
