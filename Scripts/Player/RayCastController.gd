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
	_find_raycast()

func _find_raycast() -> void:
	ray = get_tree().get_first_node_in_group(raycast_group) as RayCast3D
	if not ray:
		push_warning("RaycastDetector: No raycast found in group '%s'" % raycast_group)

func _process(_delta: float) -> void:
	if not ray or not ray.is_enabled():
		return
	
	ray.force_raycast_update()
	var collider: Node3D = ray.get_collider()
	
	var new_target: Node = _find_target_parent(collider)
	if new_target != current_target:
		current_target = new_target
		target_changed.emit(current_target)

func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("interact"):
		return
	
	if not current_target:
		return
	
	if current_target.has_method("on_interact"):
		current_target.on_interact()
		get_viewport().set_input_as_handled()

func _find_target_parent(node: Node) -> Node:
	if not node:
		return null
	
	var current: Node = node
	while current:
		for group_name in target_groups:
			if current.is_in_group(group_name):
				return current
		current = current.get_parent()
	
	return null

func get_current_target() -> Node:
	return current_target

func is_looking_at_target() -> bool:
	return current_target != null
