extends Node

var menu_scene = preload("res://Assets/Scene/main_menu.tscn")
var menu_instance: Node = null

func _input(event):
	if event.is_action_pressed("ui_cancel"): # Esc
		if menu_instance == null:
			open_menu()
		else:
			close_menu()

func open_menu():
	menu_instance = menu_scene.instantiate()
	add_child(menu_instance)

	# показать курсор
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func close_menu():
	if menu_instance:
		menu_instance.queue_free()
		menu_instance = null

	# скрыть курсор
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
