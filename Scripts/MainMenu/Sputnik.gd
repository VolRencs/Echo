extends Node3D

@export var rotation_speed := Vector3(7.5, 5.0, 3.0)
@export var blink_interval := 1.0
@export var light_on_duration := 0.2
@export var emission_energy := 2.0
@export var emission_color := Color(1, 0.1, 0.1, 0.7)

var light: Light3D
var bulb_mesh: MeshInstance3D
var blink_timer := 0.0
var is_light_on := false
static var shared_rotation := Vector3.ZERO

func _ready():
	rotation_degrees = shared_rotation
	bulb_mesh = $BulbMesh
	if bulb_mesh:
		for child in bulb_mesh.get_children():
			if child is Light3D:
				light = child
				break
		var mat = StandardMaterial3D.new()
		mat.emission_enabled = true
		mat.emission = emission_color
		mat.emission_energy_multiplier = 0.0
		bulb_mesh.material_override = mat
	if light:
		light.visible = false

func _process(delta):
	rotation_degrees += rotation_speed * delta
	shared_rotation = rotation_degrees
	if not light or not bulb_mesh:
		return
	blink_timer += delta
	if (is_light_on and blink_timer >= light_on_duration) or (not is_light_on and blink_timer >= blink_interval):
		is_light_on = !is_light_on
		blink_timer = 0.0
		light.visible = is_light_on
		bulb_mesh.material_override.emission_energy_multiplier = float(emission_energy if is_light_on else 0.0)
