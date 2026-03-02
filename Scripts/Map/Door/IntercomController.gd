extends Node3D

@export var door: Node3D
@export var label_controllers_group: String = "LabelControllers"

var label_controllers: Array[Node] = []
var raycast_detector: RaycastDetector
var intercom_sound: AudioStreamPlayer

func _ready() -> void:
	_setup_raycast()
	_cache_label_controllers()
	_cache_intercom_sound()
	hide_labels()

func _setup_raycast() -> void:
	raycast_detector = RaycastDetector.instance
	if raycast_detector:
		raycast_detector.target_changed.connect(_on_target_changed)

func _cache_label_controllers() -> void:
	label_controllers = get_tree().get_nodes_in_group(label_controllers_group)

func _cache_intercom_sound() -> void:
	var sound_nodes := get_tree().get_nodes_in_group("Sound")
	for node in sound_nodes:
		if node.name == "Intercom" and node is AudioStreamPlayer:
			intercom_sound = node
			break

func _on_target_changed(new_target: Node) -> void:
	if new_target == self:
		show_labels()
	else:
		hide_labels()

func show_labels() -> void:
	for lc in label_controllers:
		if lc and is_ancestor_of(lc):
			lc.visible = true

func hide_labels() -> void:
	for lc in label_controllers:
		if lc and is_ancestor_of(lc):
			lc.visible = false

func on_interact() -> void:
	if not door or not door.has_method("on_interact"):
		push_warning("DoorController: No valid door assigned")
		return
	
	if door.door_open:
		return
	
	if intercom_sound:
		if intercom_sound.playing:
			intercom_sound.stop()
		intercom_sound.play()
	
	door.on_interact()
