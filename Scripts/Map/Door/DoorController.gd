extends Node3D

@onready var anim = $Door_Vert_01/AnimationPlayer
@onready var DoorSound: AudioStreamPlayer3D = $Door

@export var sound: AudioStream

var door_open = false

func _ready():
	$Timer.timeout.connect(door_close)
	anim.connect("animation_finished", Callable(self, "_on_animation_finished"))

func on_interact():
	if not door_open:
		$Timer.start()
		anim.play("Open")
		DoorSound.stream = sound
		DoorSound.play()
		door_open = true

func door_close():
	$Timer.stop()
	anim.play("Close")
	DoorSound.stream = sound
	DoorSound.play()
	

func _on_animation_player_animation_finished(anim_name: String):
	if anim_name == "Close":
		door_open = false
