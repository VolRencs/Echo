extends Node3D

@export var rpm: float = 100.0
@export var local_axis: Vector3 = Vector3(0, 0, 1)

func _process(delta: float) -> void:
	var degrees_per_second = rpm * 360.0 / 60.0
	rotate_object_local(local_axis.normalized(), deg_to_rad(degrees_per_second * delta))
