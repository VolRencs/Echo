extends Node3D

# ─── EXPORTS ──────────────────────────────────────────────────────────────────

@export var asteroid_count   := 100
@export var min_speed        := 5.0
@export var max_speed        := 15.0
@export var area_size        := Vector3(40, 40, 40)
@export var asteroid_models: Array[PackedScene] = []

@export_enum("left", "right", "front", "back", "top", "bottom")
var spawn_side := "left"

# ─── CONSTANTS ────────────────────────────────────────────────────────────────

const SIDES := {
	"left":   [Vector3(-1,  0,  0), Vector3(0.01, 1,    1   )],
	"right":  [Vector3( 1,  0,  0), Vector3(0.01, 1,    1   )],
	"front":  [Vector3( 0,  0, -1), Vector3(1,    1,    0.01)],
	"back":   [Vector3( 0,  0,  1), Vector3(1,    1,    0.01)],
	"top":    [Vector3( 0,  1,  0), Vector3(1,    0.01, 1   )],
	"bottom": [Vector3( 0, -1,  0), Vector3(1,    0.01, 1   )],
}

# ─── STATE ────────────────────────────────────────────────────────────────────

class Asteroid:
	var node: Node3D
	var vel:  Vector3
	var rot:  Vector3

var _asteroids:     Array[Asteroid] = []
var _camera:        Camera3D
var _half_area:     Vector3
var _max_dist_sq:   float
var _side_highlight: MeshInstance3D

# ─── READY ────────────────────────────────────────────────────────────────────

func _ready() -> void:
	await get_tree().process_frame

	_camera = get_viewport().get_camera_3d()
	if not _camera:
		push_error("AsteroidSpawner: No Camera3D found in viewport!")
		return

	_half_area   = area_size * 0.5
	_max_dist_sq = (_camera.far * 2.0) ** 2

	add_child(_make_box(area_size, Color(0, 1, 0, 0.2)))
	_side_highlight = _make_box(Vector3.ONE * 0.01, Color(1, 0, 0, 0.5))
	add_child(_side_highlight)
	_refresh_highlight()

	$Timer.timeout.connect(_spawn)
	if $Timer.is_stopped():
		$Timer.start()

# ─── SPAWN ────────────────────────────────────────────────────────────────────

func _spawn() -> void:
	if _asteroids.size() >= asteroid_count or asteroid_models.is_empty():
		return

	var pos := _pick_spawn_pos()

	var vel := (global_position - pos + Vector3(
		randf_range(-0.3, 0.3),
		randf_range(-0.3, 0.3),
		randf_range(-0.3, 0.3)
	)).normalized() * randf_range(min_speed, max_speed)

	var node := asteroid_models[randi() % asteroid_models.size()].instantiate() as Node3D
	node.position = pos
	node.scale    = Vector3.ONE * 0.1
	add_child(node)

	var a        := Asteroid.new()
	a.node       = node
	a.vel        = vel
	a.rot        = Vector3(randf_range(-0.5, 0.5), randf_range(-0.5, 0.5), randf_range(-0.5, 0.5))
	_asteroids.append(a)

func _pick_spawn_pos() -> Vector3:
	var c := global_position
	var h := _half_area

	var r1 := Vector3(randf_range(-h.x, h.x), randf_range(-h.y, h.y), randf_range(-h.z, h.z))

	match spawn_side:
		"left":   return Vector3(c.x - h.x, c.y + r1.y, c.z + r1.z)
		"right":  return Vector3(c.x + h.x, c.y + r1.y, c.z + r1.z)
		"front":  return Vector3(c.x + r1.x, c.y + r1.y, c.z - h.z)
		"back":   return Vector3(c.x + r1.x, c.y + r1.y, c.z + h.z)
		"top":    return Vector3(c.x + r1.x, c.y + h.y,  c.z + r1.z)
		"bottom": return Vector3(c.x + r1.x, c.y - h.y,  c.z + r1.z)

	return c

# ─── PROCESS ──────────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if not _camera:
		return

	var center := global_position

	for i in range(_asteroids.size() - 1, -1, -1):
		var a := _asteroids[i]

		a.node.position += a.vel * delta
		a.node.rotate_x(a.rot.x * delta)
		a.node.rotate_y(a.rot.y * delta)
		a.node.rotate_z(a.rot.z * delta)

		if a.node.position.distance_squared_to(center) > _max_dist_sq:
			a.node.queue_free()
			_asteroids.remove_at(i)

# ─── HELPERS ──────────────────────────────────────────────────────────────────

func _make_box(size: Vector3, color: Color) -> MeshInstance3D:
	var mi  := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mi.mesh  = box

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mi.material_override = mat
	return mi

func _refresh_highlight() -> void:
	if not SIDES.has(spawn_side) or not _side_highlight:
		return
	_side_highlight.position = SIDES[spawn_side][0] * _half_area
	_side_highlight.scale    = SIDES[spawn_side][1] * area_size

func clear_asteroids() -> void:
	for a in _asteroids:
		a.node.queue_free()
	_asteroids.clear()
