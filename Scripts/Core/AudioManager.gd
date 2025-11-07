extends AudioStreamPlayer

@export var scenes_to_play: Array[String] = []

func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)
	_update_playback()

func _on_node_added(node: Node) -> void:
	if node == get_tree().current_scene:
		_update_playback()

func _update_playback() -> void:
	var scene = get_tree().current_scene
	if not scene or (scene.name in scenes_to_play) == is_playing():
		return
	if scene.name in scenes_to_play:
		play()
	else:
		stop()
