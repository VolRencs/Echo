extends Node3D

# ─── EXPORTS ──────────────────────────────────────────────────────────────────

@export var door: Node3D
@export var label_controllers_group := "LabelControllers"

# ─── STATE ────────────────────────────────────────────────────────────────────

var _label_controllers: Array[Node]
var _raycast:           RaycastDetector
var _intercom_sound:    AudioStreamPlayer

# ─── READY ────────────────────────────────────────────────────────────────────

func _ready() -> void:
	for child in find_children("*", "Node", true):
		if child.is_in_group(label_controllers_group):
			_label_controllers.append(child)

	for node in get_tree().get_nodes_in_group("Sound"):
		if node.name == "Intercom" and node is AudioStreamPlayer:
			_intercom_sound = node
			break

	_set_labels_visible(false)
	call_deferred("_setup_raycast")

func _setup_raycast() -> void:
	_raycast = RaycastDetector.instance
	if _raycast:
		_raycast.target_changed.connect(_on_target_changed)
	else:
		push_warning("DoorController: RaycastDetector instance not found")

# ─── HANDLERS ─────────────────────────────────────────────────────────────────

func _on_target_changed(new_target: Node) -> void:
	_set_labels_visible(new_target == self)

func on_interact() -> void:
	if not door or not door.has_method("on_interact"):
		push_warning("DoorController: No valid door assigned")
		return

	if door.door_open:
		return

	if _intercom_sound:
		_intercom_sound.stop()
		_intercom_sound.play()

	door.on_interact()

# ─── HELPERS ──────────────────────────────────────────────────────────────────

func _set_labels_visible(value: bool) -> void:
	for lc in _label_controllers:
		if lc:
			lc.visible = value
