extends Node3D

@export var door: Node3D
 
func on_interact():
	print("1")
	if door and door.has_method("on_interact"):
		var doorstatus = door.door_open
		if doorstatus == false:
			if AudioManager.has_node("Intercom"):
				var Intercom = AudioManager.get_node("Intercom") as AudioStreamPlayer
				if Intercom.playing:
					Intercom.stop()
				Intercom.play()
		door.on_interact()
