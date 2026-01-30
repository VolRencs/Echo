extends Node

@export var save_path: String = "user://game_save.dat"

var loaded_player_data: Dictionary = {}
var loaded_scene_data: PackedScene = null

func save_game(position: Vector3, rotation_y: float) -> bool:
	var save_data: Dictionary = {
		"player_data": {
			"position": position,
			"rotation_y": rotation_y
		},
		"scene_path": get_tree().current_scene.scene_file_path
	}

	var file := FileAccess.open(save_path, FileAccess.WRITE)
	file.store_var(save_data)
	return true

func load_game() -> bool:
	if not FileAccess.file_exists(save_path):
		return false
	var file := FileAccess.open(save_path, FileAccess.READ)

	var save_data: Dictionary = {}
	save_data = file.get_var()

	loaded_player_data = save_data.get("player_data", {})
	var scene_path: String = ""
	scene_path = save_data.get("scene_path", "")

	if scene_path != "":
		loaded_scene_data = load(scene_path)
	else:
		loaded_scene_data = null
	return true

func delete_save() -> bool:
	if not FileAccess.file_exists(save_path):
		return true
	
	var err: Error = DirAccess.remove_absolute(save_path)
	if err != OK:
		return false
	
	clear_loaded_data()
	return true

func clear_loaded_data() -> void:
	loaded_player_data.clear()
	loaded_scene_data = null

func has_save() -> bool:
	return FileAccess.file_exists(save_path)
