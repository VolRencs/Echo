extends Node3D

@export var rotation_speed_x: float = 7.5
@export var rotation_speed_y: float = 5.0
@export var rotation_speed_z: float = 3.0
@export var blink_interval: float = 1.0
@export var light_on_duration: float = 0.2
@export var emission_energy: float = 2.0
@export var emission_color: Color = Color(1.0, 0.1, 0.1, 0.706)

static var shared_rotation: Vector3 = Vector3(0.0, 4.0, 0.0)
var light: Light3D
var bulb_mesh: MeshInstance3D
var blink_timer: float = 0.0
var is_light_on: bool = false

func _ready():
	rotation = shared_rotation
	
	bulb_mesh = find_child("BulbMesh")
	if bulb_mesh:
		for child in bulb_mesh.get_children():
			if child is Light3D:
				light = child
				break
		
		var material = StandardMaterial3D.new()
		material.emission_enabled = true
		material.emission = emission_color
		material.emission_energy_multiplier = 0.0
		bulb_mesh.material_override = material
	
	if light:
		light.visible = false

func _process(delta):
	rotate_x(deg_to_rad(rotation_speed_x * delta))
	rotate_y(deg_to_rad(rotation_speed_y * delta))
	rotate_z(deg_to_rad(rotation_speed_z * delta))
	
	shared_rotation = rotation
	
	if light and bulb_mesh:
		blink_timer += delta
		if is_light_on:
			if blink_timer >= light_on_duration:
				light.visible = false
				bulb_mesh.material_override.emission_energy_multiplier = 0.0
				is_light_on = false
				blink_timer = 0.0
		else:
			if blink_timer >= blink_interval:
				light.visible = true
				bulb_mesh.material_override.emission_energy_multiplier = emission_energy
				is_light_on = true
				blink_timer = 0.0
