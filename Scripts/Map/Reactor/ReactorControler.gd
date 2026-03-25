extends Node

const STATUS_ENABLED := 1
const STATUS_ALARM := 2
const STATUS_DISABLED := 3

const REACTOR_STATUS_COLOR_DISABLED := Color(0.97, 0.0, 0.032, 1.0)
const REACTOR_STATUS_COLOR_ALARM := Color(0.738, 0.396, 0.004, 1.0)
const REACTOR_STATUS_COLOR_ENABLED := Color(0.232, 0.975, 0.0, 1.0)

@export var reactor_status: int = STATUS_ENABLED:
	set(value):
		_reactor_status = clampi(value, STATUS_ENABLED, STATUS_DISABLED)
		_apply_status_color()
	get:
		return _reactor_status

@onready var reactor_node: Node = $root/GLTF_SceneRootNode/Bomb_0/Object_8

var _reactor_status := STATUS_ENABLED
var _reactor_mesh: MeshInstance3D
var _override_material: StandardMaterial3D

func _ready() -> void:
	_reactor_mesh = reactor_node as MeshInstance3D
	if not _reactor_mesh:
		push_error("Узел найден, но он не MeshInstance3D.")
		return

	var source_material := _reactor_mesh.get_active_material(0)
	if not source_material:
		push_error("ReactorControler: Reactor material not found")
		return

	_override_material = source_material.duplicate() as StandardMaterial3D
	if not _override_material:
		push_error("ReactorControler: Reactor material must be StandardMaterial3D")
		return

	_reactor_mesh.set_surface_override_material(0, _override_material)
	_apply_status_color()

func _apply_status_color() -> void:
	if not _override_material:
		return

	match _reactor_status:
		STATUS_ENABLED:
			_override_material.albedo_color = REACTOR_STATUS_COLOR_ENABLED
		STATUS_ALARM:
			_override_material.albedo_color = REACTOR_STATUS_COLOR_ALARM
		STATUS_DISABLED:
			_override_material.albedo_color = REACTOR_STATUS_COLOR_DISABLED
