extends Node3D

@export var area_size: Vector3 = Vector3(40, 40, 40)
@export var highlight_side: String = "left" # Сторона, которую подсветить

var mesh_instance: MeshInstance3D
var highlight_mesh: MeshInstance3D

func _ready():
	# Основной куб зоны
	mesh_instance = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = area_size
	mesh_instance.mesh = box
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0, 1, 0, 0.2) # зелёный полупрозрачный
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.flags_transparent = true
	mesh_instance.material_override = mat
	add_child(mesh_instance)
	
	# Подсветка выбранной стороны
	highlight_mesh = MeshInstance3D.new()
	var side_box = BoxMesh.new()
	# Размер “плоской” грани — очень тонкая по толщине
	side_box.size = Vector3(area_size.x, area_size.y, area_size.z) * 0.01
	highlight_mesh.mesh = side_box
	
	var highlight_mat = StandardMaterial3D.new()
	highlight_mat.albedo_color = Color(1, 0, 0, 0.5) # красный полупрозрачный
	highlight_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	highlight_mat.flags_transparent = true
	highlight_mesh.material_override = highlight_mat
	add_child(highlight_mesh)
	
	update_highlight_position()


func update_highlight_position():
	var half = area_size / 2
	match highlight_side:
		"left":
			highlight_mesh.position = Vector3(-half.x, 0, 0)
			highlight_mesh.scale = Vector3(0.01, 1, 1)
		"right":
			highlight_mesh.position = Vector3(half.x, 0, 0)
			highlight_mesh.scale = Vector3(0.01, 1, 1)
		"front":
			highlight_mesh.position = Vector3(0, 0, -half.z)
			highlight_mesh.scale = Vector3(1, 1, 0.01)
		"back":
			highlight_mesh.position = Vector3(0, 0, half.z)
			highlight_mesh.scale = Vector3(1, 1, 0.01)
		"top":
			highlight_mesh.position = Vector3(0, half.y, 0)
			highlight_mesh.scale = Vector3(1, 0.01, 1)
		"bottom":
			highlight_mesh.position = Vector3(0, -half.y, 0)
			highlight_mesh.scale = Vector3(1, 0.01, 1)
