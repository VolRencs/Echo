extends SpotLight3D

# ─── EXPORTS ──────────────────────────────────────────────────────────────────

@export_category("Light Settings")
@export var energy_on:  float = 8.0
@export var energy_off: float = 0.0
@export var fade_speed: float = 8.0

@export_category("Flicker")
@export var flicker_enabled:   bool  = false
@export var flicker_intensity: float = 0.3
@export var flicker_frequency: float = 12.0

@export_category("Position")
@export var offset: Vector3 = Vector3(0.2, -0.3, -0.5)

# ─── STATE ────────────────────────────────────────────────────────────────────

var is_on: bool = false

var _sound:              AudioStreamPlayer
var _parent:             Node3D
var _target_energy:      float = 0.0
var _flicker_timer:      float = 0.0
var _flicker_multiplier: float = 0.0

# ─── READY ────────────────────────────────────────────────────────────────────

func _ready() -> void:
	light_energy    = energy_off
	_target_energy  = energy_off
	_flicker_multiplier = flicker_intensity * 0.2

	_parent = get_parent() as Node3D
	if _parent:
		global_position = _parent.global_position + offset

	for node in get_tree().get_nodes_in_group("Sound"):
		if node.name == "Lighter" and node is AudioStreamPlayer:
			_sound = node
			break

# ─── PROCESS ──────────────────────────────────────────────────────────────────

func _physics_process(_delta: float) -> void:
	if _parent:
		global_position = _parent.global_position + offset

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("flashlight"):
		toggle()

	light_energy = lerp(light_energy, _target_energy, fade_speed * delta)

	if flicker_enabled and is_on:
		_flicker_timer += delta * flicker_frequency
		light_energy = clamp(
			light_energy + sin(_flicker_timer) * _flicker_multiplier,
			energy_off, energy_on
		)

# ─── PUBLIC API ───────────────────────────────────────────────────────────────

func toggle(silent: bool = false) -> void:
	is_on          = not is_on
	_target_energy = energy_on if is_on else energy_off
	if not silent and _sound:
		_sound.play()

func turn_on(silent: bool = false) -> void:
	if not is_on: toggle(silent)

func turn_off(silent: bool = false) -> void:
	if is_on: toggle(silent)

func set_state_silent(new_state: bool) -> void:
	if is_on != new_state: toggle(true)
