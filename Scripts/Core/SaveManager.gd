extends Node

@export var save_path: String = "user://game_save.tres"
var loaded_player_data: Dictionary = {}
var loaded_scene_data: PackedScene = null

func save_game(position: Vector3, rotation_y: float) -> void:	
	var save_data = GameSave.new()
	save_data.player_data = {"position": position, "rotation_y": rotation_y}

	if get_tree().current_scene and get_tree().current_scene.name != "":
		var packed_scene = PackedScene.new()
		if packed_scene.pack(get_tree().current_scene) == OK:
			save_data.scene_data = packed_scene
			loaded_scene_data = packed_scene
		
	ResourceSaver.save(save_data, save_path)

func load_game() -> void:
	if not FileAccess.file_exists(save_path):
		return
	
	var save_data = ResourceLoader.load(save_path) as GameSave
	if save_data:
		loaded_player_data = save_data.player_data
		loaded_scene_data = save_data.scene_data

func clear_loaded_data() -> void:
	loaded_player_data = {}
	loaded_scene_data = null

func delete_save() -> void:
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(save_path)
