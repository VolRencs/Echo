extends Node3D

@export var rpm: float = 100.0
@export var local_axis: Vector3 = Vector3(0, 0, 1)

var _rotation_speed: float = 0.0
var _normalized_axis: Vector3 = Vector3.ZERO

func _ready() -> void:
	_update_rotation_parameters()

func _update_rotation_parameters() -> void:
	var degrees_per_second: float = rpm * 360.0 / 60.0
	_rotation_speed = deg_to_rad(degrees_per_second)
	_normalized_axis = local_axis.normalized()

func _process(delta: float) -> void:
	rotate_object_local(_normalized_axis, _rotation_speed * delta)

func set_rpm(new_rpm: float) -> void:
	rpm = new_rpm
	_update_rotation_parameters()

func set_axis(new_axis: Vector3) -> void:
	local_axis = new_axis
	_update_rotation_parameters()
