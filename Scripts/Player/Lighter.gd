extends SpotLight3D

@export_category("Light Settings")
@export var energy_on: float = 8.0
@export var energy_off: float = 0.0
@export var fade_speed: float = 8.0

@export_category("Flicker")
@export var flicker_enabled: bool = false
@export var flicker_intensity: float = 0.3
@export var flicker_frequency: float = 12.0

@export_category("Position")
@export var offset: Vector3 = Vector3(0.2, -0.3, -0.5)

var is_on: bool = false
var flicker_timer: float = 0.0
var _sound: AudioStreamPlayer = null
var _parent_node: Node3D = null

var _target_energy: float = 0.0
var _flicker_multiplier: float = 0.0

func _ready() -> void:
	light_energy = energy_off
	_target_energy = energy_off
	
	_parent_node = get_parent()
	if _parent_node:
		global_position = _parent_node.global_position + offset
	
	_find_sound_player()
	
	_flicker_multiplier = flicker_intensity * 0.2

func _find_sound_player() -> void:
	var sound_nodes := get_tree().get_nodes_in_group("Sound")
	for node in sound_nodes:
		if node.name == "Lighter" and node is AudioStreamPlayer:
			_sound = node
			return

func _physics_process(_delta: float) -> void:
	if _parent_node:
		global_position = _parent_node.global_position + offset

func _process(delta: float) -> void:
	_handle_input()
	_update_light_energy(delta)

func _handle_input() -> void:
	if not Input.is_action_just_pressed("flashlight"):
		return
	
	is_on = not is_on
	_target_energy = energy_on if is_on else energy_off
	
	if _sound:
		_sound.play()

func _update_light_energy(delta: float) -> void:
	light_energy = lerp(light_energy, _target_energy, fade_speed * delta)
	
	if flicker_enabled and is_on:
		_apply_flicker(delta)

func _apply_flicker(delta: float) -> void:
	flicker_timer += delta * flicker_frequency
	
	var flicker_offset := sin(flicker_timer) * _flicker_multiplier
	light_energy = clamp(
		light_energy + flicker_offset,
		energy_off,
		energy_on
	)

func turn_on() -> void:
	if is_on:
		return
	is_on = true
	_target_energy = energy_on
	if _sound:
		_sound.play()

func turn_off() -> void:
	if not is_on:
		return
	is_on = false
	_target_energy = energy_off
	if _sound:
		_sound.play()

func toggle() -> void:
	if is_on:
		turn_off()
	else:
		turn_on()

func set_state_silent(new_state: bool) -> void:
	is_on = new_state
	_target_energy = energy_on if is_on else energy_off
