extends Node

# ─── EXPORTS ──────────────────────────────────────────────────────────────────

@export var save_path := "user://game_save.dat"

# ─── STATE ────────────────────────────────────────────────────────────────────

var loaded_player_data: Dictionary = {}
var loaded_scene_data:  PackedScene

# ─── PUBLIC API ───────────────────────────────────────────────────────────────

func has_save() -> bool:
	return FileAccess.file_exists(save_path)

func save_game(position: Vector3, rotation_y: float) -> bool:
	var current_scene := get_tree().current_scene
	if not current_scene:
		push_error("SaveManager: Cannot save game without an active scene")
		return false

	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if not file:
		push_error("SaveManager: Cannot open file for writing: %s" % save_path)
		return false

	file.store_var({
		"player_data": { "position": position, "rotation_y": rotation_y },
		"scene_path":  current_scene.scene_file_path,
	})
	return true

func load_game() -> bool:
	if not has_save():
		return false

	var file := FileAccess.open(save_path, FileAccess.READ)
	if not file:
		push_error("SaveManager: Cannot open file for reading: %s" % save_path)
		return false

	var raw_data: Variant = file.get_var()
	if typeof(raw_data) != TYPE_DICTIONARY:
		push_error("SaveManager: Save file is corrupted or has an unexpected format")
		clear_loaded_data()
		return false

	var data: Dictionary = raw_data as Dictionary
	var player_data_value: Variant = data.get("player_data", {})
	loaded_player_data = player_data_value as Dictionary if typeof(player_data_value) == TYPE_DICTIONARY else {}

	var scene_path_value: Variant = data.get("scene_path", "")
	var scene_path := String(scene_path_value)
	loaded_scene_data = null
	if not scene_path.is_empty():
		var scene_resource: Resource = load(scene_path)
		if scene_resource is PackedScene:
			loaded_scene_data = scene_resource as PackedScene
		else:
			push_error("SaveManager: Cannot load saved scene: %s" % scene_path)
	return true

func delete_save() -> bool:
	if not has_save():
		return true

	var err := DirAccess.remove_absolute(save_path)
	if err != OK:
		push_error("SaveManager: Cannot delete save file (error %d)" % err)
		return false

	clear_loaded_data()
	return true

func clear_loaded_data() -> void:
	loaded_player_data.clear()
	loaded_scene_data = null
