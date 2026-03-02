extends Node3D

@export var asteroid_count := 100
@export var min_speed := 5.0
@export var max_speed := 15.0
@export var asteroid_models: Array[PackedScene] = []
@export var area_size := Vector3(40, 40, 40)
@export var spawn_side := "left"

var asteroids := []
var area_mesh: MeshInstance3D
var side_highlight: MeshInstance3D
var camera: Camera3D
var _timer: Timer
var _half_area: Vector3
var _max_distance: float

const SIDES := {
	"left":   [Vector3(-1, 0, 0), Vector3(0.01, 1, 1)],
	"right":  [Vector3( 1, 0, 0), Vector3(0.01, 1, 1)],
	"front":  [Vector3( 0, 0,-1), Vector3(1, 1, 0.01)],
	"back":   [Vector3( 0, 0, 1), Vector3(1, 1, 0.01)],
	"top":    [Vector3( 0, 1, 0), Vector3(1, 0.01, 1)],
	"bottom": [Vector3( 0,-1, 0), Vector3(1, 0.01, 1)]
}

func _ready() -> void:
	await get_tree().process_frame
	
	camera = get_viewport().get_camera_3d()
	if not camera:
		push_error("AsteroidSpawner: No camera found!")
	else:
		_max_distance = camera.far * 2.0
	
	_half_area = area_size * 0.5
	
	area_mesh = _create_mesh(area_size, Color(0, 1, 0, 0.2))
	side_highlight = _create_mesh(Vector3.ONE * 0.01, Color(1, 0, 0, 0.5))
	add_child(area_mesh)
	add_child(side_highlight)
	_update_highlight()
	
	_timer = $Timer
	_timer.timeout.connect(_spawn_asteroid)
	if _timer.is_stopped():
		_timer.start()

func _create_mesh(size: Vector3, color: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mi.material_override = mat
	
	return mi

func _update_highlight() -> void:
	if not SIDES.has(spawn_side):
		return
	
	var dir: Vector3 = SIDES[spawn_side][0]
	var side_scale: Vector3 = SIDES[spawn_side][1]
	
	side_highlight.position = dir * _half_area
	side_highlight.scale = side_scale * area_size

func _spawn_asteroid() -> void:
	if asteroids.size() >= asteroid_count:
		return
	
	if asteroid_models.is_empty():
		return
	
	var pos := _spawn_position()
	var vel := (global_position - pos).normalized()
	vel += Vector3(
		randf_range(-0.3, 0.3),
		randf_range(-0.3, 0.3),
		randf_range(-0.3, 0.3)
	)
	vel = vel.normalized() * randf_range(min_speed, max_speed)
	
	var model_idx := randi() % asteroid_models.size()
	var model := asteroid_models[model_idx].instantiate() as Node3D
	
	add_child(model)
	model.position = pos
	model.scale = Vector3.ONE * 0.1
	
	asteroids.append({
		"node": model,
		"pos": pos,
		"vel": vel,
		"rot": Vector3(
			randf_range(-0.5, 0.5),
			randf_range(-0.5, 0.5),
			randf_range(-0.5, 0.5)
		)
	})

func _spawn_position() -> Vector3:
	var center := global_position
	var h := _half_area
	
	match spawn_side:
		"left":
			return Vector3(
				center.x - h.x,
				randf_range(center.y - h.y, center.y + h.y),
				randf_range(center.z - h.z, center.z + h.z)
			)
		"right":
			return Vector3(
				center.x + h.x,
				randf_range(center.y - h.y, center.y + h.y),
				randf_range(center.z - h.z, center.z + h.z)
			)
		"front":
			return Vector3(
				randf_range(center.x - h.x, center.x + h.x),
				randf_range(center.y - h.y, center.y + h.y),
				center.z - h.z
			)
		"back":
			return Vector3(
				randf_range(center.x - h.x, center.x + h.x),
				randf_range(center.y - h.y, center.y + h.y),
				center.z + h.z
			)
		"top":
			return Vector3(
				randf_range(center.x - h.x, center.x + h.x),
				center.y + h.y,
				randf_range(center.z - h.z, center.z + h.z)
			)
		"bottom":
			return Vector3(
				randf_range(center.x - h.x, center.x + h.x),
				center.y - h.y,
				randf_range(center.z - h.z, center.z + h.z)
			)
	
	return center

func _process(delta: float) -> void:
	if not camera:
		return
	
	var center := global_position
	
	for i in range(asteroids.size() - 1, -1, -1):
		var asteroid: Dictionary = asteroids[i]
		var node: Node3D = asteroid.node
		var pos: Vector3 = asteroid.pos
		var vel: Vector3 = asteroid.vel
		var rot: Vector3 = asteroid.rot
		
		pos += vel * delta
		asteroid.pos = pos
		node.position = pos
		
		node.rotate_x(rot.x * delta)
		node.rotate_y(rot.y * delta)
		node.rotate_z(rot.z * delta)
		
		if pos.distance_squared_to(center) > _max_distance * _max_distance:
			node.queue_free()
			asteroids.remove_at(i)

func clear_asteroids() -> void:
	for asteroid in asteroids:
		asteroid.node.queue_free()
	asteroids.clear()
