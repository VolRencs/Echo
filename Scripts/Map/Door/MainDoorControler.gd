extends Node

@onready var DoorRightAnim = $Door_Right_01/AnimationPlayer
@onready var DoorLeftAnim = $Door_Left_01/AnimationPlayer
@onready var DoorOpenSound: AudioStreamPlayer3D = $"../AudioStreamPlayer3D"

@onready var SoundOpen = load("res://Assets/Audio/Dver_O.ogg")
@onready var SoundClose = load("res://Assets/Audio/Dver_Z.ogg")

var door_open: bool = false

func _ready():
	$Timer.timeout.connect(door_close)
	
func on_interact():
	if not door_open:
		$Timer.start()
		DoorOpenSound.stream = SoundOpen
		DoorOpenSound.play()
		DoorLeftAnim.play("DoorLeftOpen")
		DoorRightAnim.play("DoorRightOpen")
		door_open = true

func door_close():
	$Timer.stop()
	DoorOpenSound.stream = SoundClose
	DoorOpenSound.play()
	DoorLeftAnim.play("DoorLeftClose")
	DoorRightAnim.play("DoorRightClose")
	door_open = false
