extends Node

@export var asteroid_count: int = 20
@export var min_speed: float = 5.0
@export var max_speed: float = 15.0
@export var max_distance_from_camera: float = 40.0
@export var save_scene_paths: Array[String] = []

var asteroids: Array[Dictionary] = []
var world_bounds: Vector3 = Vector3(20, 20, 20)

@export var asteroid_model_paths: Array[String] = [
	"res://Assets/Models/asteroid/Rock01/Rock01.glb",
    "res://Assets/Models/asteroid/Rock02/Rock02.glb"
]

func _ready():
	var current_scene_path = get_tree().current_scene.scene_file_path if get_tree().current_scene else ""
	if save_scene_paths.is_empty() or not current_scene_path in save_scene_paths:
		set_process(false)
		return
	if asteroid_model_paths.is_empty():
		return
	var camera = get_viewport().get_camera_3d() if get_viewport().get_camera_3d() else Node3D.new()
	camera.position = Vector3.ZERO
	if AsteroidState.has_saved_state():
		asteroids = AsteroidState.load_state()
		restore_asteroids()
	else:
		spawn_asteroids()
	AsteroidState.save_state(asteroids)

func spawn_asteroids():
	asteroids.clear()
	var camera = get_viewport().get_camera_3d() if get_viewport().get_camera_3d() else Node3D.new()
	camera.position = Vector3.ZERO
	for i in range(asteroid_count):
		var model_path = asteroid_model_paths[randi() % asteroid_model_paths.size()]
		var asteroid_state = {"position": generate_valid_position(camera), "velocity": Vector3.ZERO, "model_path": model_path}
		asteroids.append(asteroid_state)
		randomize_velocity(asteroid_state)
		create_asteroid_visual(asteroid_state)

func generate_valid_position(camera: Node3D) -> Vector3:
	var position
	var attempts = 0
	const MAX_ATTEMPTS = 50
	while attempts < MAX_ATTEMPTS:
		position = Vector3(randf_range(-world_bounds.x, world_bounds.x), randf_range(-world_bounds.y, world_bounds.y), randf_range(-world_bounds.z, world_bounds.z))
		if position.distance_to(camera.global_transform.origin) <= max_distance_from_camera:
			return position
		attempts += 1
	return camera.global_transform.origin + (position.normalized() * max_distance_from_camera)

func create_asteroid_visual(state: Dictionary):
	var asteroid_scene = load(state.model_path)
	if not asteroid_scene:
		return
	var asteroid = asteroid_scene.instantiate() as Node3D
	if not asteroid:
		return
	add_child(asteroid)
	asteroid.position = state.position
	asteroid.scale = Vector3(0.1, 0.1, 0.1)

func restore_asteroids():
	for state in asteroids:
		var asteroid_scene = load(state.model_path)
		if not asteroid_scene:
			continue
		var asteroid = asteroid_scene.instantiate() as Node3D
		if not asteroid:
			continue
		add_child(asteroid)
		asteroid.position = state.position
		asteroid.scale = Vector3(0.1, 0.1, 0.1)

func _process(delta):
	for i in range(asteroids.size()):
		var state = asteroids[i]
		var asteroid = get_child(i + 1) if i + 1 < get_child_count() else null
		if asteroid:
			asteroid.position += state.velocity * delta
			if state.position.x < -world_bounds.x or state.position.x > world_bounds.x or \
			   state.position.y < -world_bounds.y or state.position.y > world_bounds.y or \
			   state.position.z < -world_bounds.z or state.position.z > world_bounds.z:
				wrap_around(i)

func randomize_velocity(state: Dictionary):
	var theta = randf_range(0, TAU)
	var phi = randf_range(0, PI)
	var speed = randf_range(min_speed, max_speed)
	state.velocity = Vector3(cos(theta) * sin(phi), cos(phi), sin(theta) * sin(phi)) * speed

func wrap_around(index: int):
	if index < asteroids.size():
		var state = asteroids[index]
		var asteroid = get_child(index + 1) if index + 1 < get_child_count() else null
		if asteroid:
			if state.position.x < -world_bounds.x: state.position.x = world_bounds.x
			elif state.position.x > world_bounds.x: state.position.x = -world_bounds.x
			if state.position.y < -world_bounds.y: state.position.y = world_bounds.y
			elif state.position.y > world_bounds.y: state.position.y = -world_bounds.y
			if state.position.z < -world_bounds.z: state.position.z = world_bounds.z
			elif state.position.z > world_bounds.z: state.position.z = -world_bounds.z
			asteroid.position = state.position

func _exit_tree():
	var current_scene_path = get_tree().current_scene.scene_file_path if get_tree().current_scene else ""
	if not save_scene_paths.is_empty() and current_scene_path in save_scene_paths:
		AsteroidState.save_state(asteroids)
