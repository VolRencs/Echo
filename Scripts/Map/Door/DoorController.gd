extends Node3D

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var door_sound: AudioStreamPlayer3D = $Door
@onready var timer: Timer = $Timer

@export var sound: AudioStream
@export var auto_close_time: float = 3.0

var door_open: bool = false

func _ready() -> void:
	if sound:
		door_sound.stream = sound
	
	timer.timeout.connect(_on_timer_timeout)
	timer.wait_time = auto_close_time
	anim.animation_finished.connect(_on_animation_finished)

func on_interact() -> void:
	if door_open:
		return
	
	open_door()

func open_door() -> void:
	if door_open or anim.is_playing():
		return
	
	door_open = true
	anim.play("Door/Open")
	door_sound.play()
	timer.start()

func close_door() -> void:
	if not door_open or anim.is_playing():
		return
	
	timer.stop()
	anim.play("Door/Close")
	door_sound.play()

func _on_timer_timeout() -> void:
	close_door()

func _on_animation_finished(anim_name: String) -> void:
	if anim_name == "Door/Close":
		door_open = false
