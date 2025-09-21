extends Node3D

@export var area_size: Vector3 = Vector3(40, 40, 40)
@export var highlight_side: String = "left" # Options: left, right, front, back, top, bottom

var mesh_instance: MeshInstance3D
var highlight_mesh: MeshInstance3D

func _ready() -> void:
	mesh_instance = create_mesh_instance(area_size, Color(0, 1, 0, 0.2))
	add_child(mesh_instance)
	
	highlight_mesh = create_mesh_instance(Vector3.ZERO, Color(1, 0, 0, 0.5))
	add_child(highlight_mesh)
	
	update_highlight_position()

func create_mesh_instance(size: Vector3, color: Color) -> MeshInstance3D:
	var new_mesh_instance = MeshInstance3D.new() # Изменено имя переменной
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
	
	if config.has(highlight_side):
		highlight_mesh.position = config[highlight_side].position
		highlight_mesh.scale = config[highlight_side].scale
