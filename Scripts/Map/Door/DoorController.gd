extends Node3D

@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var door_sound: AudioStreamPlayer3D = $Door

@export var sound: AudioStream

var door_open: bool = false

func _ready():
	door_sound.stream = sound
	$Timer.timeout.connect(door_close)
	anim.connect("animation_finished", Callable(self, "_on_animation_finished"))

func on_interact():
	if not door_open:
		$Timer.start()
		if not anim.is_playing():
			anim.play("Door/Open")
		door_sound.play()
		door_open = true

func door_close():
	$Timer.stop()
	if not anim.is_playing():
		anim.play("Door/Close")
	door_sound.play()

func _on_animation_finished(anim_name: String):
	if anim_name == "Door/Close":
		door_open = false
