extends Node3D

@export var asteroid_count: int = 100
@export var min_speed: float = 5.0
@export var max_speed: float = 15.0
@export var max_distance_from_camera: float = 50.0
@export var asteroid_models_paths: Array[PackedScene] = []
@export var area_size: Vector3 = Vector3(40, 40, 40)
@export var spawn_side: String = "left"  # Options: left, right, front, back, top, bottom

var asteroids: Array[Dictionary] = []
var mesh_instance: MeshInstance3D
var highlight_mesh: MeshInstance3D

func _ready():
	mesh_instance = create_mesh_instance(area_size, Color(0, 1, 0, 0.2))
	add_child(mesh_instance)
	
	highlight_mesh = create_mesh_instance(Vector3.ZERO, Color(1, 0, 0, 0.5))
	add_child(highlight_mesh)
	update_highlight_position()
	
	$Timer.timeout.connect(spawn_single_asteroid)
	$Timer.start()

func create_mesh_instance(size: Vector3, color: Color) -> MeshInstance3D:
	var new_mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = size if size != Vector3.ZERO else area_size * 0.01
	new_mesh_instance.mesh = box_mesh
	
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	new_mesh_instance.material_override = material
	
	return new_mesh_instance

func update_highlight_position() -> void:
	var half = area_size / 2
	var config = {
		"left":   { "position": Vector3(-half.x, 0, 0), "scale": Vector3(0.01, 1, 1) },
		"right":  { "position": Vector3(half.x, 0, 0),  "scale": Vector3(0.01, 1, 1) },
		"front":  { "position": Vector3(0, 0, -half.z), "scale": Vector3(1, 1, 0.01) },
		"back":   { "position": Vector3(0, 0, half.z),  "scale": Vector3(1, 1, 0.01) },
		"top":    { "position": Vector3(0, half.y, 0),  "scale": Vector3(1, 0.01, 1) },
		"bottom": { "position": Vector3(0, -half.y, 0), "scale": Vector3(1, 0.01, 1) }
	}
	
	if config.has(spawn_side):
		highlight_mesh.position = config[spawn_side].position
		highlight_mesh.scale = config[spawn_side].scale

func spawn_single_asteroid():
	if asteroids.size() >= asteroid_count: return
	var state = {
		"position": generate_spawn_position(),
		"velocity": generate_velocity(),
		"model_path": asteroid_models_paths[randi() % asteroid_models_paths.size()],
		"rotation_velocity": Vector3(randf_range(-0.5, 0.5), randf_range(-0.5, 0.5), randf_range(-0.5, 0.5))
	}
	asteroids.append(state)
	create_asteroid_visual(state)

func generate_spawn_position() -> Vector3:
	var center = global_position
	var size = area_size
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
	var direction = (global_position - generate_spawn_position()).normalized()
	direction += Vector3(randf_range(-0.3, 0.3), randf_range(-0.3, 0.3), randf_range(-0.3, 0.3))
	return direction.normalized() * randf_range(min_speed, max_speed)

func create_asteroid_visual(state: Dictionary):
	var asteroid = state.model_path.instantiate() as Node3D
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
		if state.position.distance_to(global_position) > max_distance_from_camera:
			state.node.queue_free()
			asteroids.remove_at(i)
