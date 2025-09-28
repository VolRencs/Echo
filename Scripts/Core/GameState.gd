extends Node

var loaded_player_data: Dictionary = {}
var loaded_scene_data: PackedScene = null

func clear_loaded_data() -> void:
	loaded_player_data = {}
	loaded_scene_data = null
