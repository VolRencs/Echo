extends SpotLight3D

@export var energy_on: float = 8.0
@export var energy_off: float = 0.0
@export var fade_speed: float = 8.0
@export var flicker_enabled: bool = false
@export var flicker_intensity: float = 0.3
@export var flicker_frequency: float = 12.0
@export var offset: Vector3 = Vector3(0.2, -0.3, -0.5)

var is_on: bool = false
var flicker_timer: float = 0.0
var _sound: AudioStreamPlayer = null

func _ready():
	light_energy = energy_off
	global_transform.origin = get_parent().global_transform.origin + offset
	
	for node in get_tree().get_nodes_in_group("Sound"):
		if node.name == "Lighter" and node is AudioStreamPlayer:
			_sound = node
			break

func _process(delta):
	if Input.is_action_just_pressed("flashlight"):
		is_on = !is_on
		if _sound: _sound.play()
	
	var target = energy_on if is_on else energy_off
	light_energy = lerp(light_energy, target, fade_speed * delta)

	if flicker_enabled and is_on:
		flicker_timer += delta * flicker_frequency
		light_energy = clamp(light_energy + sin(flicker_timer) * flicker_intensity * 0.2, energy_off, energy_on)
