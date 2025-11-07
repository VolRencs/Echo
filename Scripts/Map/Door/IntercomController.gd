extends Node3D

@export var door: Node3D
 
func on_interact():
	if not door or not door.has_method("on_interact"):
		return
	if not door.door_open:
		var players := get_tree().get_nodes_in_group("Sound")
		for p in players:
			if p is AudioStreamPlayer and p.name == "Intercom":
				if p.playing:
					p.stop()
				p.play()
				break
	door.on_interact()
