extends Node3D

# ─── EXPORTS ──────────────────────────────────────────────────────────────────

@export var door: Node
@export var label_controllers_group: StringName = &"LabelControllers"

# ─── STATE ────────────────────────────────────────────────────────────────────

var _label_controllers: Array[Node]
var _raycast:           RaycastDetector
var _intercom_sound:    AudioStreamPlayer

# ─── READY ────────────────────────────────────────────────────────────────────

func _ready() -> void:
	_label_controllers = NodeUtils.collect_descendants_in_group(self, label_controllers_group)
	_intercom_sound = NodeUtils.find_audio_stream_player(get_tree(), &"Intercom")

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

	if not _door_can_interact():
		return

	if _intercom_sound:
		_intercom_sound.stop()
		_intercom_sound.play()

	door.call("on_interact")

# ─── HELPERS ──────────────────────────────────────────────────────────────────

func _set_labels_visible(value: bool) -> void:
	for lc in _label_controllers:
		if lc:
			lc.set("visible", value)

func _door_can_interact() -> bool:
	if not door:
		return false

	if door.has_method("can_interact"):
		var result: Variant = door.call("can_interact")
		if typeof(result) == TYPE_BOOL:
			return bool(result)

	if door.has_method("is_door_open"):
		var is_open: Variant = door.call("is_door_open")
		if typeof(is_open) == TYPE_BOOL and bool(is_open):
			return false

	return true
