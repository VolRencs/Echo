extends Control
class_name ChestInventory

@export var slot_scene: PackedScene
var is_open := false

func _ready():
	visible = false

func open():
	visible = true
	is_open = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func close():
	visible = false
	is_open = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
