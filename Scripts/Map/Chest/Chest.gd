extends Node3D

@export var interact_text: String = "Нажмите \"E\""
@export var animated_objects: Array[Node3D] = []
@export var open_angle: float = 40.0
@export var speed: float = 5.0
@export var label_offset: Vector3 = Vector3(-0.1, 2.8, 1.6)
@export var chest_inventory: ChestInventory

var label_3d: Label3D = null
var is_open: bool = false
var target_angles: Array[float] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	label_3d = Label3D.new()
	label_3d.text = interact_text
	label_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label_3d.visible = false
	label_3d.position = label_offset
	add_child(label_3d)
	
	if RaycastDetector.instance:
		RaycastDetector.instance.target_changed.connect(_on_target_changed)
	
	target_angles.clear()
	for obj in animated_objects:
		if obj:
			target_angles.append(obj.rotation.z)

func _on_target_changed(new_target: Node) -> void:
	label_3d.visible = new_target == self

func _process(delta: float) -> void:
	for i in range(animated_objects.size()):
		var obj = animated_objects[i]
		if obj:
			var current_z = obj.rotation.z
			obj.rotation.z = lerp(current_z, target_angles[i], delta * speed)

func _input(event: InputEvent) -> void:
	if is_open:
		if event.is_action_pressed("ui_cancel"):
			get_viewport().set_input_as_handled()
			return
		if event.is_action_pressed("interact"):
			on_interact()
			get_viewport().set_input_as_handled()

func on_interact() -> void:
	is_open = not is_open
	
	if is_open:
		chest_inventory.open()
	else:
		chest_inventory.close()

	for i in range(animated_objects.size()):
		if animated_objects[i]:
			target_angles[i] = deg_to_rad(open_angle if is_open else 0.0)
