extends Node3D

# ─── EXPORTS ──────────────────────────────────────────────────────────────────

@export var rotation_speed:    Vector3 = Vector3(7.5, 5.0, 3.0)
@export var blink_interval:    float   = 1.0
@export var light_on_duration: float   = 0.2
@export var emission_energy:   float   = 2.0
@export var emission_color:    Color   = Color(1, 0.1, 0.1, 0.7)

# ─── STATE ────────────────────────────────────────────────────────────────────

static var shared_rotation := Vector3.ZERO

var _light:        Light3D
var _material:     StandardMaterial3D
var _blink_timer:  float = 0.0
var _light_on:     bool  = false

# ─── READY ────────────────────────────────────────────────────────────────────

func _ready() -> void:
	rotation_degrees = shared_rotation

	var bulb_mesh := $BulbMesh as MeshInstance3D
	if not bulb_mesh:
		push_warning("Beacon: BulbMesh not found")
		return

	for child in bulb_mesh.get_children():
		if child is Light3D:
			_light = child
			_light.visible = false
			break

	_material = StandardMaterial3D.new()
	_material.emission_enabled           = true
	_material.emission                   = emission_color
	_material.emission_energy_multiplier = 0.0
	bulb_mesh.material_override          = _material

# ─── PROCESS ──────────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	rotation_degrees += rotation_speed * delta
	shared_rotation   = rotation_degrees

	if not _light or not _material:
		return

	_blink_timer += delta

	var threshold := light_on_duration if _light_on else blink_interval
	if _blink_timer < threshold:
		return

	_blink_timer = 0.0
	_light_on    = not _light_on
	_light.visible                       = _light_on
	_material.emission_energy_multiplier = emission_energy if _light_on else 0.0
