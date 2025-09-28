extends Node

@onready var reactor_node = $root/GLTF_SceneRootNode/Bomb_0/Object_8

var reactor_status_color_disabled: Color = Color(0.97, 0.0, 0.032, 1.0)
var reactor_status_color_alarm: Color = Color(0.738, 0.396, 0.004, 1.0)
var reactor_status_color_enabled: Color = Color(0.232, 0.975, 0.0, 1.0)

var reactor_status: int = 1

func _physics_process(_delta) -> void:
	if reactor_node is MeshInstance3D:
		var mat = reactor_node.mesh.surface_get_material(0)
		if mat:
			var new_mat = mat.duplicate()
			reactor_node.set_surface_override_material(0, new_mat)
			
			match reactor_status:
				1:
					new_mat.albedo_color = reactor_status_color_enabled
				2:
					new_mat.albedo_color = reactor_status_color_alarm
				3:
					new_mat.albedo_color = reactor_status_color_disabled
	else:
		push_error("Узел найден, но он не MeshInstance3D.")
