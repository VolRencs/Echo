extends Node3D

@onready var anim = $Door_Vert_01/AnimationPlayer

var door_open = false

func _ready():
	$Timer.timeout.connect(door_close)
	anim.connect("animation_finished", Callable(self, "_on_animation_finished"))

func on_interact():
	if not door_open:
		$Timer.start()
		anim.play("Open")
		play_sound_Door()
		door_open = true

func door_close():
	$Timer.stop()
	anim.play("Close")
	play_sound_Door()
	
func play_sound_Door():
	if AudioManager.has_node("SecondDoor"):
		var SecondDoor = AudioManager.get_node("SecondDoor") as AudioStreamPlayer
		if SecondDoor.playing:
			SecondDoor.stop()
		SecondDoor.play()

func _on_animation_player_animation_finished(anim_name: String):
	if anim_name == "Close":
		door_open = false
