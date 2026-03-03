extends Node3D

# ─── EXPORTS ──────────────────────────────────────────────────────────────────

@export var rpm:        float   = 100.0
@export var local_axis: Vector3 = Vector3(0, 0, 1)

# ─── STATE ────────────────────────────────────────────────────────────────────

var _speed: float
var _axis:  Vector3

# ─── READY ────────────────────────────────────────────────────────────────────

func _ready() -> void:
	_recalc()

# ─── PROCESS ──────────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	rotate_object_local(_axis, _speed * delta)

# ─── PUBLIC API ───────────────────────────────────────────────────────────────

func set_rpm(new_rpm: float) -> void:
	rpm = new_rpm
	_recalc()

func set_axis(new_axis: Vector3) -> void:
	local_axis = new_axis
	_recalc()

# ─── HELPERS ──────────────────────────────────────────────────────────────────

func _recalc() -> void:
	_speed = deg_to_rad(rpm * 6.0)
	_axis  = local_axis.normalized()
