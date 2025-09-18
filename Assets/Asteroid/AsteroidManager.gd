extends Node3D

@export var asteroid_count: int = 100
@export var min_speed: float = 5.0
@export var max_speed: float = 15.0
@export var max_distance_from_camera: float = 50
@export var spawn_interval: float = 1
@export var asteroid_model_paths: Array[String] = [
	"res://Assets/Models/asteroid/Rock01/Rock01.glb",
	"res://Assets/Models/asteroid/Rock02/Rock02.glb"
]

var asteroids: Array[Dictionary] = []
var spawn_timer: Timer

var timer
var asteroid_count_Debug: int = 0

func _ready():
	$Timer.start()
	$Timer.timeout.connect(_on_Timer_timeout)

func _on_Timer_timeout():
	spawn_single_asteroid()

func spawn_single_asteroid():
	asteroid_count_Debug += 1
	var model_path = asteroid_model_paths[randi() % asteroid_model_paths.size()]
	var pos = generate_spawn_position_side()
	var velocity = generate_velocity_towards_center(pos)
	var asteroid_state = {
		"position": pos,
		"velocity": velocity,
		"model_path": model_path
	}
	asteroids.append(asteroid_state)
	create_asteroid_visual(asteroid_state)
	print("Asteroid Spawn: " + str(asteroid_count_Debug))

# Спавн сбоку: случайная сторона X или Z, случайная высота Y
func generate_spawn_position_side() -> Vector3:
	var side = randi() % 4
	var x = 0.0
	var y = randf_range(-max_distance_from_camera/2, max_distance_from_camera/2)
	var z = 0.0
	match side:
		0: # слева
			x = -max_distance_from_camera
			z = randf_range(-max_distance_from_camera, max_distance_from_camera)
		1: # справа
			x = max_distance_from_camera
			z = randf_range(-max_distance_from_camera, max_distance_from_camera)
		2: # спереди
			z = -max_distance_from_camera
			x = randf_range(-max_distance_from_camera, max_distance_from_camera)
		3: # сзади
			z = max_distance_from_camera
			x = randf_range(-max_distance_from_camera, max_distance_from_camera)
	return Vector3(x, y, z)

# Движение к центру сцены с небольшим рандомным смещением
func generate_velocity_towards_center(position: Vector3) -> Vector3:
	var direction = -position.normalized() + Vector3(
		randf_range(-0.2, 0.2),
		randf_range(-0.2, 0.2),
		randf_range(-0.2, 0.2)
	)
	direction = direction.normalized()
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

		# Удаляем, если астероид ушёл за пределы зоны
		if state.position.length() > max_distance_from_camera * 1.5:
			state.node.queue_free()
			asteroids.remove_at(i)
