extends Node3D

@export var asteroid_count: int = 100
@export var min_speed: float = 5.0
@export var max_speed: float = 15.0
@export var max_distance_from_camera: float = 50
@export var asteroid_model_paths: Array[String] = [
	"res://Assets/Models/asteroid/Rock01/Rock01.glb",
	"res://Assets/Models/asteroid/Rock02/Rock02.glb"
]
@export var spawn_area_path: NodePath
@export var spawn_side: String = "left"

var asteroids: Array[Dictionary] = []
@onready var spawn_area: Node3D = get_node(spawn_area_path)

func _ready():
	$Timer.timeout.connect(spawn_single_asteroid)
	$Timer.start()

func spawn_single_asteroid():
	if asteroids.size() >= asteroid_count: return
	var state = {
		"position": generate_spawn_position(),
		"velocity": generate_velocity(),
		"model_path": asteroid_model_paths[randi() % asteroid_model_paths.size()],
		"rotation_velocity": Vector3(randf_range(-0.5, 0.5), randf_range(-0.5, 0.5), randf_range(-0.5, 0.5))
	}
	asteroids.append(state)
	create_asteroid_visual(state)

func generate_spawn_position() -> Vector3:
	var center = spawn_area.global_position
	var size = spawn_area.scale * 2
	var pos = Vector3.ZERO
	match spawn_side:
		"left":
			pos = Vector3(center.x - size.x/2, randf_range(center.y - size.y/2, center.y + size.y/2), randf_range(center.z - size.z/2, center.z + size.z/2))
		"right":
			pos = Vector3(center.x + size.x/2, randf_range(center.y - size.y/2, center.y + size.y/2), randf_range(center.z - size.z/2, center.z + size.z/2))
		"front":
			pos = Vector3(randf_range(center.x - size.x/2, center.x + size.x/2), randf_range(center.y - size.y/2, center.y + size.y/2), center.z - size.z/2)
		"back":
			pos = Vector3(randf_range(center.x - size.x/2, center.x + size.x/2), randf_range(center.y - size.y/2, center.y + size.y/2), center.z + size.z/2)
		"top":
			pos = Vector3(randf_range(center.x - size.x/2, center.x + size.x/2), center.y + size.y/2, randf_range(center.z - size.z/2, center.z + size.z/2))
		"bottom":
			pos = Vector3(randf_range(center.x - size.x/2, center.x + size.x/2), center.y - size.y/2, randf_range(center.z - size.z/2, center.z + size.z/2))
	return pos

func generate_velocity() -> Vector3:
	var direction = (spawn_area.global_position - generate_spawn_position()).normalized()
	direction += Vector3(randf_range(-0.3, 0.3), randf_range(-0.3, 0.3), randf_range(-0.3, 0.3))
	return direction.normalized() * randf_range(min_speed, max_speed)

func create_asteroid_visual(state: Dictionary):
	var asteroid = load(state.model_path).instantiate() as Node3D
	add_child(asteroid)
	state.node = asteroid
	asteroid.position = state.position
	asteroid.scale = Vector3(0.1, 0.1, 0.1)

func _process(delta):
	for i in range(asteroids.size() - 1, -1, -1):
		var state = asteroids[i]
		state.position += state.velocity * delta
		state.node.position = state.position
		state.node.rotate_x(state.rotation_velocity.x * delta)
		state.node.rotate_y(state.rotation_velocity.y * delta)
		state.node.rotate_z(state.rotation_velocity.z * delta)
		if state.position.distance_to(spawn_area.global_position) > max_distance_from_camera:
			state.node.queue_free()
			asteroids.remove_at(i)
