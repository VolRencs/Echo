extends SpotLight3D

@export var energy_on: float = 8.0
@export var energy_off: float = 0.0
@export var fade_speed: float = 2.0
@export var flicker_enabled: bool = false
@export var flicker_intensity: float = 0.5
@export var flicker_frequency: float = 5.0
@export var offset: Vector3 = Vector3(0.2, -0.3, -0.5)

var is_on: bool = false
var target_energy: float = 0.0
var flicker_timer: float = 0.0

func _ready():
	light_energy = energy_off
	target_energy = energy_off
	transform.origin = offset

func _process(delta):
	if Input.is_action_just_pressed("flashlight"):
		toggle_flashlight()

	if light_energy != target_energy:
		light_energy = lerp(light_energy, target_energy, fade_speed * delta)

	if flicker_enabled and is_on:
		flicker_timer += delta * flicker_frequency
		var flicker = sin(flicker_timer) * flicker_intensity
		light_energy = clamp(target_energy + flicker, energy_off, energy_on)

func toggle_flashlight():
	is_on = !is_on
	target_energy = energy_on if is_on else energy_off
	
	# Проигрываем звук через AudioManager, если есть LighterPlayer
	if AudioManager.has_node("LighterPlayer"):
		var player = AudioManager.get_node("LighterPlayer")
		player.play()
