extends Node3D

@export var rotation_speed := Vector3(7.5, 5.0, 3.0)
@export var blink_interval := 1.0
@export var light_on_duration := 0.2
@export var emission_energy := 2.0
@export var emission_color := Color(1, 0.1, 0.1, 0.7)

var light: Light3D
var bulb_mesh: MeshInstance3D
var bulb_material: StandardMaterial3D
var blink_timer := 0.0
var is_light_on := false

static var shared_rotation := Vector3.ZERO

func _ready() -> void:
	rotation_degrees = shared_rotation
	
	bulb_mesh = $BulbMesh
	if not bulb_mesh:
		push_warning("Beacon: BulbMesh not found")
		return
	
	_find_light()
	_setup_material()

func _find_light() -> void:
	for child in bulb_mesh.get_children():
		if child is Light3D:
			light = child
			light.visible = false
			break

func _setup_material() -> void:
	bulb_material = StandardMaterial3D.new()
	bulb_material.emission_enabled = true
	bulb_material.emission = emission_color
	bulb_material.emission_energy_multiplier = 0.0
	bulb_mesh.material_override = bulb_material

func _process(delta: float) -> void:
	rotation_degrees += rotation_speed * delta
	shared_rotation = rotation_degrees
	
	if not light or not bulb_material:
		return
	
	_update_blink(delta)

func _update_blink(delta: float) -> void:
	blink_timer += delta
	
	var should_toggle := false
	if is_light_on:
		if blink_timer >= light_on_duration:
			should_toggle = true
	else:
		if blink_timer >= blink_interval:
			should_toggle = true
	
	if should_toggle:
		is_light_on = not is_light_on
		blink_timer = 0.0
		light.visible = is_light_on
		bulb_material.emission_energy_multiplier = emission_energy if is_light_on else 0.0
