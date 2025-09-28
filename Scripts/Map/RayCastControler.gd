extends Node

@onready var ray = $"../CameraPoint/Camera3D/RayCast3D"
@onready var LabelControler = get_node("/root/Game/SpaceShip/Doors/Door_Vert_03/E")
var current_target: Node = null

func _process(_delta):
	current_target = null
	var collider = ray.get_collider()
	var intercom_node = find_intercom_parent(collider)
	current_target = intercom_node

func find_intercom_parent(node: Node) -> Node:
	var current = node
	while current:
		if current.is_in_group("Intercom"):
			LabelControler.enable_Label()
			return current
		current = current.get_parent()
	LabelControler.disable_Label()
	return null
	
func _input(event):
	if event.is_action_pressed("interact") and current_target:
		if current_target.has_method("on_interact"):
			current_target.on_interact() 
