extends Node
class_name RaycastDetector

signal target_changed(new_target: Node)

@export var raycast_group: String = "RayCast"
@export var target_groups: Array[String] = ["Intercom"]

var ray: RayCast3D
var current_target: Node = null

static var instance: RaycastDetector

func _ready() -> void:
	instance = self
	ray = get_tree().get_first_node_in_group(raycast_group) as RayCast3D

func _process(_delta: float) -> void:
	if not ray or not ray.is_enabled():
		return
	
	ray.force_raycast_update()
	var collider = ray.get_collider()
	
	var new_target = find_target_parent(collider)
	if new_target != current_target:
		current_target = new_target
		target_changed.emit(current_target)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and current_target and current_target.has_method("on_interact"):
		current_target.on_interact()
		get_viewport().set_input_as_handled()

func find_target_parent(node: Node) -> Node:
	var current = node
	while current:
		for group_name in target_groups:
			if current.is_in_group(group_name):
				return current
		current = current.get_parent()
	return null
