extends Node

@onready var door_right_anim: AnimationPlayer = $Door_Right_01/AnimationPlayer
@onready var door_left_anim: AnimationPlayer = $Door_Left_01/AnimationPlayer
@onready var door_sound: AudioStreamPlayer3D = $Door

@export var sound_open: AudioStream
@export var sound_close: AudioStream

var door_open: bool = false

func _ready():
	$Timer.timeout.connect(door_close)

func on_interact():
	if not door_open:
		$Timer.start()
		_play_door(sound_open, "DoorLeftOpen", "DoorRightOpen")
		door_open = true

func door_close():
	$Timer.stop()
	_play_door(sound_close, "DoorLeftClose", "DoorRightClose")

func _play_door(sound: AudioStream, left_anim: String, right_anim: String):
	door_sound.stream = sound
	door_sound.play()
	door_left_anim.play(left_anim)
	door_right_anim.play(right_anim)

func _on_animation_player_animation_finished(anim_name: String):
	if anim_name == "DoorRightClose":
		door_open = false
