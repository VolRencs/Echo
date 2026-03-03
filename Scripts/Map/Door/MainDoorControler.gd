extends Node

# ─── NODES ────────────────────────────────────────────────────────────────────

@onready var _anim:  AnimationPlayer     = $AnimationPlayer
@onready var _sound: AudioStreamPlayer3D = $Door
@onready var _timer: Timer               = $Timer

# ─── EXPORTS ──────────────────────────────────────────────────────────────────

@export var sound_open:      AudioStream
@export var sound_close:     AudioStream
@export var auto_close_time: float = 3.0

# ─── STATE ────────────────────────────────────────────────────────────────────

var door_open: bool = false

# ─── READY ────────────────────────────────────────────────────────────────────

func _ready() -> void:
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
	_play(sound_open, "Anim/Open")
	_timer.start()

func close_door() -> void:
	if not door_open or _anim.is_playing():
		return
	_timer.stop()
	_play(sound_close, "Anim/Close")

# ─── HANDLERS ─────────────────────────────────────────────────────────────────

func _on_animation_finished(anim_name: String) -> void:
	if anim_name == "Anim/Close":
		door_open = false

# ─── HELPERS ──────────────────────────────────────────────────────────────────

func _play(stream: AudioStream, anim_name: String) -> void:
	if stream:
		_sound.stream = stream
		_sound.play()
	if _anim.has_animation(anim_name):
		_anim.play(anim_name)
