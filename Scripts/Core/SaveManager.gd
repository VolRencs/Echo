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
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if not file:
		push_error("SaveManager: Cannot open file for writing: %s" % save_path)
		return false

	file.store_var({
		"player_data": { "position": position, "rotation_y": rotation_y },
		"scene_path":  get_tree().current_scene.scene_file_path,
	})
	return true

func load_game() -> bool:
	if not has_save():
		return false

	var file := FileAccess.open(save_path, FileAccess.READ)
	if not file:
		push_error("SaveManager: Cannot open file for reading: %s" % save_path)
		return false

	var data: Dictionary = file.get_var()
	loaded_player_data = data.get("player_data", {})

	var scene_path: String = data.get("scene_path", "")
	loaded_scene_data = load(scene_path) if scene_path else null
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
