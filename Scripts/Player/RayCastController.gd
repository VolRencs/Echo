extends Node

@onready var ray: RayCast3D = $"../Camera3D/RayCast3D"
@onready var label_controllers = get_tree().get_nodes_in_group("LabelControllers")
var current_target: Node = null

func _ready() -> void:
	for lc in label_controllers:
		lc.visible = false

func _process(_delta: float) -> void:
	var collider: Node = ray.get_collider()
	var intercom_node: Node = find_intercom_parent(collider)

	if intercom_node != current_target:
		if current_target:
			enable_labels_for_target(null)
		current_target = intercom_node
		if current_target:
			enable_labels_for_target(current_target)

func enable_labels_for_target(target: Node) -> void:
	for lc in label_controllers:
		lc.visible = target != null and target.is_ancestor_of(lc)

func find_intercom_parent(node: Node) -> Node:
	var current: Node = node
	while current:
		if current.is_in_group("Intercom"):
			return current
		current = current.get_parent()
	return null

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and current_target and current_target.has_method("on_interact"):
		current_target.on_interact()
