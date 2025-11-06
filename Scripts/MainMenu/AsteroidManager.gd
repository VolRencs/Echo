extends Node3D

@export var asteroid_count := 100
@export var min_speed := 5.0
@export var max_speed := 15.0
@export var removal_distance_multiplier := 2.0
@export var asteroid_models: Array[PackedScene] = []
@export var area_size := Vector3(40, 40, 40)
@export var spawn_side := "left"

var asteroids := []
var area_mesh: MeshInstance3D
var side_highlight: MeshInstance3D
var removal_distance: float = 200.0

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
	var camera := get_viewport().get_camera_3d()
	if camera and camera.far > 0:
		removal_distance = camera.far * removal_distance_multiplier
	
	area_mesh = _create_mesh(area_size, Color(0, 1, 0, 0.2))
	side_highlight = _create_mesh(Vector3.ONE * 0.01, Color(1, 0, 0, 0.5))
	add_child(area_mesh)
	add_child(side_highlight)
	_update_highlight()
	
	$Timer.timeout.connect(_spawn_asteroid)
	if $Timer.is_stopped():
		$Timer.start()

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
	if not SIDES.has(spawn_side): return
	var half := area_size * 0.5
	var dir: Vector3 = SIDES[spawn_side][0]
	var scale: Vector3 = SIDES[spawn_side][1]
	side_highlight.position = dir * half
	side_highlight.scale = scale * area_size

func _spawn_asteroid() -> void:
	if asteroids.size() >= asteroid_count: return
	if asteroid_models.is_empty(): return
	
	var pos := _spawn_position()
	var vel := (global_position - pos).normalized()
	vel += Vector3(randf_range(-0.3, 0.3), randf_range(-0.3, 0.3), randf_range(-0.3, 0.3))
	vel = vel.normalized() * randf_range(min_speed, max_speed)
	
	var model := asteroid_models[randi() % asteroid_models.size()].instantiate() as Node3D
	add_child(model)
	model.position = pos
	model.scale = Vector3.ONE * 0.1
	
	asteroids.append({
		"node": model,
		"pos": pos,
		"vel": vel,
		"rot": Vector3(randf_range(-0.5, 0.5), randf_range(-0.5, 0.5), randf_range(-0.5, 0.5))
	})

func _spawn_position() -> Vector3:
	var c := global_position
	var h := area_size * 0.5
	match spawn_side:
		"left":   return Vector3(c.x - h.x, randf_range(c.y - h.y, c.y + h.y), randf_range(c.z - h.z, c.z + h.z))
		"right":  return Vector3(c.x + h.x, randf_range(c.y - h.y, c.y + h.y), randf_range(c.z - h.z, c.z + h.z))
		"front":  return Vector3(randf_range(c.x - h.x, c.x + h.x), randf_range(c.y - h.y, c.y + h.y), c.z - h.z)
		"back":   return Vector3(randf_range(c.x - h.x, c.x + h.x), randf_range(c.y - h.y, c.y + h.y), c.z + h.z)
		"top":    return Vector3(randf_range(c.x - h.x, c.x + h.x), c.y + h.y, randf_range(c.z - h.z, c.z + h.z))
		"bottom": return Vector3(randf_range(c.x - h.x, c.x + h.x), c.y - h.y, randf_range(c.z - h.z, c.z + h.z))
	return c

func _process(delta: float) -> void:
	var center := global_position
	for i in range(asteroids.size() - 1, -1, -1):
		var a = asteroids[i]
		a.pos += a.vel * delta
		a.node.position = a.pos
		a.node.rotate_x(a.rot.x * delta)
		a.node.rotate_y(a.rot.y * delta)
		a.node.rotate_z(a.rot.z * delta)
		
		if a.pos.distance_to(center) > removal_distance:
			a.node.queue_free()
			asteroids.remove_at(i)
