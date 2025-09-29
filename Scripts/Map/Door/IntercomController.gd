extends Node3D

@export var door: Node3D
 
func on_interact():
	print("1")
	if door and door.has_method("on_interact"):
		var doorstatus = door.door_open
		if doorstatus == false:
			var players = get_tree().get_nodes_in_group("Sound")
			for player in players:
				if player.name == "Intercom" and player is AudioStreamPlayer:
					if player.playing:
						player.stop()
					player.play()
					break
		door.on_interact()
