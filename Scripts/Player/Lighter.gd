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
var _target_energy:      float = 0.0
var _flicker_timer:      float = 0.0
var _flicker_multiplier: float = 0.0

# ─── READY ────────────────────────────────────────────────────────────────────

func _ready() -> void:
	light_energy    = energy_off
	_target_energy  = energy_off
	_flicker_multiplier = flicker_intensity * 0.2
	position = offset

	_sound = NodeUtils.find_audio_stream_player(get_tree(), &"Lighter")
	_sync_processing()

# ─── PROCESS ──────────────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("flashlight"):
		toggle()

func _process(delta: float) -> void:
	if not is_equal_approx(light_energy, _target_energy):
		light_energy = lerpf(light_energy, _target_energy, fade_speed * delta)
		if absf(light_energy - _target_energy) <= 0.01:
			light_energy = _target_energy

	if flicker_enabled and is_on:
		_flicker_timer += delta * flicker_frequency
		light_energy = clamp(
			light_energy + sin(_flicker_timer) * _flicker_multiplier,
			energy_off, energy_on
		)

	_sync_processing()

# ─── PUBLIC API ───────────────────────────────────────────────────────────────

func toggle(silent: bool = false) -> void:
	is_on          = not is_on
	_target_energy = energy_on if is_on else energy_off
	if not silent and _sound:
		_sound.play()
	_sync_processing()

func turn_on(silent: bool = false) -> void:
	if not is_on: toggle(silent)

func turn_off(silent: bool = false) -> void:
	if is_on: toggle(silent)

func set_state_silent(new_state: bool) -> void:
	if is_on != new_state: toggle(true)

func _sync_processing() -> void:
	set_process(
		(flicker_enabled and is_on)
		or not is_equal_approx(light_energy, _target_energy)
	)
