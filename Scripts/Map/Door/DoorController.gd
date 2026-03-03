extends Node3D

# ─── NODES ────────────────────────────────────────────────────────────────────

@onready var _anim:  AnimationPlayer    = $AnimationPlayer
@onready var _sound: AudioStreamPlayer3D = $Door
@onready var _timer: Timer              = $Timer

# ─── EXPORTS ──────────────────────────────────────────────────────────────────

@export var sound:           AudioStream
@export var auto_close_time: float = 3.0

# ─── STATE ────────────────────────────────────────────────────────────────────

var door_open: bool = false

# ─── READY ────────────────────────────────────────────────────────────────────

func _ready() -> void:
	if sound:
		_sound.stream = sound

	_timer.wait_time = auto_close_time
	_timer.timeout.connect(close_door)
	_anim.animation_finished.connect(_on_animation_finished)

# ─── PUBLIC API ───────────────────────────────────────────────────────────────

func on_interact() -> void:
	open_door()

func open_door() -> void:
	if door_open or _anim.is_playing():
		return

	door_open = true
	_anim.play("Door/Open")
	_sound.play()
	_timer.start()

func close_door() -> void:
	if not door_open or _anim.is_playing():
		return

	_timer.stop()
	_anim.play("Door/Close")
	_sound.play()

# ─── HANDLERS ─────────────────────────────────────────────────────────────────

func _on_animation_finished(anim_name: String) -> void:
	if anim_name == "Door/Close":
		door_open = false
