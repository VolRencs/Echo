extends Node

@onready var DoorRightAnim = $Door_Right_01/AnimationPlayer
@onready var DoorLeftAnim = $Door_Left_01/AnimationPlayer
@onready var DoorOpenSound: AudioStreamPlayer3D = $Door

@export var sound_open: AudioStream
@export var sound_close: AudioStream

var door_open: bool = false

func _ready():
	$Timer.timeout.connect(door_close)
	
func on_interact():
	if not door_open:
		$Timer.start()
		DoorOpenSound.stream = sound_open
		DoorOpenSound.play()
		DoorLeftAnim.play("DoorLeftOpen")
		DoorRightAnim.play("DoorRightOpen")
		door_open = true

func door_close():
	$Timer.stop()
	DoorOpenSound.stream = sound_close
	DoorOpenSound.play()
	DoorLeftAnim.play("DoorLeftClose")
	DoorRightAnim.play("DoorRightClose")

func _on_animation_player_animation_finished(anim_name: String):
	if anim_name == "DoorRightClose":
		door_open = false
