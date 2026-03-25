extends Node
class_name RaycastDetector

# ─── SIGNALS ──────────────────────────────────────────────────────────────────

signal target_changed(new_target: Node)

# ─── EXPORTS ──────────────────────────────────────────────────────────────────

@export var raycast_group: String         = "RayCast"
@export var target_groups: Array[String]  = ["Intercom"]

# ─── STATE ────────────────────────────────────────────────────────────────────

static var instance: RaycastDetector

var current_target: Node
var _ray:           RayCast3D

# ─── READY ────────────────────────────────────────────────────────────────────

func _ready() -> void:
	instance = self
	_ray = get_tree().get_first_node_in_group(raycast_group) as RayCast3D
	if not _ray:
		push_warning("RaycastDetector: No RayCast3D found in group '%s'" % raycast_group)

# ─── PROCESS ──────────────────────────────────────────────────────────────────

func _physics_process(_delta: float) -> void:
	if not _ray or not _ray.is_enabled():
		return

	_ray.force_raycast_update()

	var new_target := _find_target_parent(_ray.get_collider())
	if new_target != current_target:
		current_target = new_target
		target_changed.emit(current_target)

# ─── INPUT ────────────────────────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and current_target and current_target.has_method("on_interact"):
		current_target.call("on_interact")
		get_viewport().set_input_as_handled()

# ─── HELPERS ──────────────────────────────────────────────────────────────────

func _find_target_parent(node: Node) -> Node:
	var current := node
	while current:
		for group in target_groups:
			if current.is_in_group(group):
				return current
		current = current.get_parent()
	return null

# ─── PUBLIC API ───────────────────────────────────────────────────────────────

func is_looking_at_target() -> bool:
	return current_target != null
