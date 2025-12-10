extends Node

@onready var door_anim: AnimationPlayer = $AnimationPlayer
@onready var door_sound: AudioStreamPlayer3D = $Door

@export var sound_open: AudioStream
@export var sound_close: AudioStream

var door_open: bool = false

func _ready():
	$Timer.timeout.connect(door_close)
	door_anim.animation_finished.connect(_on_animation_player_animation_finished)

func on_interact():
	if not door_open:
		$Timer.start()
		_play_door(sound_open, "Anim/Open")
		door_open = true

func door_close():
	$Timer.stop()
	_play_door(sound_close, "Anim/Close")

func _play_door(sound: AudioStream, anim_name: String):
	door_sound.stream = sound
	door_sound.play()
	door_anim.play(anim_name)

func _on_animation_player_animation_finished(anim_name: String):
	if anim_name == "Anim/Close":
		door_open = false
