extends Node3D

@export var door: Node3D
@export var label_controllers_group: String = "LabelControllers"

var label_controllers: Array[Node] = []
var raycast_detector: RaycastDetector

func _ready() -> void:
	raycast_detector = RaycastDetector.instance
	if raycast_detector:
		raycast_detector.target_changed.connect(_on_target_changed)

	label_controllers = get_tree().get_nodes_in_group(label_controllers_group)
	hide_labels()

func _on_target_changed(new_target: Node) -> void:
	if new_target == self:
		show_labels()
	else:
		hide_labels()

func show_labels() -> void:
	for lc in label_controllers:
		if is_ancestor_of(lc):
			lc.visible = true

func hide_labels() -> void:
	for lc in label_controllers:
		if is_ancestor_of(lc):
			lc.visible = false

func on_interact():
	if not door or not door.has_method("on_interact"):
		return
	
	if not door.door_open:
		var players := get_tree().get_nodes_in_group("Sound")
		for p in players:
			if p is AudioStreamPlayer and p.name == "Intercom":
				if p.playing:
					p.stop()
				p.play()
				break
		door.on_interact()
