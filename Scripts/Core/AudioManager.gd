extends AudioStreamPlayer

@export var scenes_to_play: Array[String] = []

func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)
	play_if_needed()

func _on_node_added(node: Node) -> void:
	if node == get_tree().current_scene:
		play_if_needed()

func play_if_needed() -> void:
	var current_scene = get_tree().current_scene
	if current_scene == null:
		return
	
	var current_scene_name = current_scene.name
	if current_scene_name in scenes_to_play and not is_playing():
		play()
	elif not current_scene_name in scenes_to_play and is_playing():
		stop()
