extends Node

var saved_state: Array[Dictionary] = []

func save_state(state: Array[Dictionary]):
	saved_state = state.duplicate(true)

func load_state() -> Array[Dictionary]:
	return saved_state.duplicate(true)

func has_saved_state() -> bool:
	return not saved_state.is_empty()

func clear_state():
	saved_state.clear()
