extends Node3D

@export var asteroid_count: int = 100
@export var min_speed: float = 5.0
@export var max_speed: float = 15.0
@export var max_distance_from_camera: float = 50
@export var asteroid_model_paths: Array[String] = [
	"res://Assets/Models/asteroid/Rock01/Rock01.glb",
	"res://Assets/Models/asteroid/Rock02/Rock02.glb"
]

@export var spawn_area_path: NodePath # путь к SpawnArea в сцене
@export var spawn_side: String = "left" # "left", "right", "front", "back", "top", "bottom"

var asteroids: Array[Dictionary] = []
var asteroid_count_Debug: int = 0
@onready var spawn_area: Node3D = get_node(spawn_area_path)


func _ready():
	$Timer.start()
	$Timer.timeout.connect(_on_Timer_timeout)


func _on_Timer_timeout():
	if asteroids.size() < asteroid_count:
		spawn_single_asteroid()


func spawn_single_asteroid():
	asteroid_count_Debug += 1
	var model_path = asteroid_model_paths[randi() % asteroid_model_paths.size()]
	var pos = generate_spawn_position_one_side(spawn_side)
	var velocity = generate_velocity_with_offset(pos)
	var asteroid_state = {
		"position": pos,
		"velocity": velocity,
		"model_path": model_path
	}
	asteroids.append(asteroid_state)
	create_asteroid_visual(asteroid_state)
	print("Asteroid Spawn: " + str(asteroid_count_Debug))


# Спавн с одной стороны зоны
func generate_spawn_position_one_side(side: String) -> Vector3:
	var center = spawn_area.global_position
	var size = spawn_area.scale * 2

	var pos = Vector3.ZERO
	match side:
		"left":
			pos.x = center.x - size.x/2
			pos.y = randf_range(center.y - size.y/2, center.y + size.y/2)
			pos.z = randf_range(center.z - size.z/2, center.z + size.z/2)
		"right":
			pos.x = center.x + size.x/2
			pos.y = randf_range(center.y - size.y/2, center.y + size.y/2)
			pos.z = randf_range(center.z - size.z/2, center.z + size.z/2)
		"front":
			pos.z = center.z - size.z/2
			pos.x = randf_range(center.x - size.x/2, center.x + size.x/2)
			pos.y = randf_range(center.y - size.y/2, center.y + size.y/2)
		"back":
			pos.z = center.z + size.z/2
			pos.x = randf_range(center.x - size.x/2, center.x + size.x/2)
			pos.y = randf_range(center.y - size.y/2, center.y + size.y/2)
		"top":
			pos.y = center.y + size.y/2
			pos.x = randf_range(center.x - size.x/2, center.x + size.x/2)
			pos.z = randf_range(center.z - size.z/2, center.z + size.z/2)
		"bottom":
			pos.y = center.y - size.y/2
			pos.x = randf_range(center.x - size.x/2, center.x + size.x/2)
			pos.z = randf_range(center.z - size.z/2, center.z + size.z/2)
	return pos


# Движение в сторону зоны с небольшим смещением и поворотом
func generate_velocity_with_offset(position: Vector3) -> Vector3:
	var center = spawn_area.global_position
	var direction = (center - position).normalized()

	# добавляем случайное смещение
	var offset = Vector3(
		randf_range(-0.3, 0.3),
		randf_range(-0.3, 0.3),
		randf_range(-0.3, 0.3)
	)
	direction += offset
	direction = direction.normalized()

	# скорость
	var speed = randf_range(min_speed, max_speed)
	return direction * speed


func create_asteroid_visual(state: Dictionary):
	var scene = load(state.model_path)
	if not scene: return
	var asteroid = scene.instantiate() as Node3D
	if not asteroid: return
	add_child(asteroid)
	state.node = asteroid
	asteroid.position = state.position
	asteroid.scale = Vector3(0.1, 0.1, 0.1)


func _process(delta):
	for i in range(asteroids.size() - 1, -1, -1):
		var state = asteroids[i]
		if not state.has("node"): continue
		state.position += state.velocity * delta
		state.node.position = state.position

		# Удаляем, если астероид ушёл слишком далеко
		if state.position.distance_to(spawn_area.global_position) > max_distance_from_camera:
			state.node.queue_free()
			asteroids.remove_at(i)
