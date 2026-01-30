extends Node

@onready var door_anim: AnimationPlayer = $AnimationPlayer
@onready var door_sound: AudioStreamPlayer3D = $Door
@onready var timer: Timer = $Timer

@export var sound_open: AudioStream
@export var sound_close: AudioStream
@export var auto_close_time: float = 3.0

var door_open: bool = false

func _ready() -> void:
	timer.timeout.connect(_on_timer_timeout)
	timer.wait_time = auto_close_time
	door_anim.animation_finished.connect(_on_animation_finished)

func on_interact() -> void:
	if door_open:
		return
	
	open_door()

func open_door() -> void:
	if door_open or door_anim.is_playing():
		return
	
	door_open = true
	_play_door(sound_open, "Anim/Open")
	timer.start()

func close_door() -> void:
	if not door_open or door_anim.is_playing():
		return
	
	timer.stop()
	_play_door(sound_close, "Anim/Close")

func _play_door(sound: AudioStream, anim_name: String) -> void:
	if sound:
		door_sound.stream = sound
		door_sound.play()
	
	if door_anim.has_animation(anim_name):
		door_anim.play(anim_name)

func _on_timer_timeout() -> void:
	close_door()

func _on_animation_finished(anim_name: String) -> void:
	if anim_name == "Anim/Close":
		door_open = false
