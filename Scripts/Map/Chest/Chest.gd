extends Node3D
class_name Chest

@export var interact_text: String = "Нажмите \"E\""
@export var animated_objects: Array[Node3D] = []
@export var open_angle: float = 40.0
@export var speed: float = 5.0
@export var label_offset: Vector3 = Vector3(-0.1, 2.8, 1.6)
@export var chest_inventory: ChestInventory
@export var chest_id: String = ""

var label_3d: Label3D = null
var is_open: bool = false
var target_angles: Array[float] = []
var is_player_nearby: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	if chest_id.is_empty():
		chest_id = str(get_instance_id())
	
	_setup_label()
	_setup_raycast()
	_initialize_angles()
	
	if chest_inventory:
		chest_inventory.chest_closed.connect(_on_chest_closed)

func _setup_label() -> void:
	label_3d = Label3D.new()
	label_3d.text = interact_text
	label_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label_3d.visible = false
	label_3d.position = label_offset
	add_child(label_3d)

func _setup_raycast() -> void:
	if RaycastDetector.instance:
		RaycastDetector.instance.target_changed.connect(_on_target_changed)

func _initialize_angles() -> void:
	target_angles.clear()
	for obj in animated_objects:
		if obj:
			target_angles.append(obj.rotation.z)

func _on_target_changed(new_target: Node) -> void:
	is_player_nearby = new_target == self
	label_3d.visible = is_player_nearby and not is_open

func _process(delta: float) -> void:
	_animate_objects(delta)

func _animate_objects(delta: float) -> void:
	for i in range(animated_objects.size()):
		var obj := animated_objects[i]
		if obj:
			obj.rotation.z = lerp(obj.rotation.z, target_angles[i], delta * speed)

func _input(event: InputEvent) -> void:
	if not is_player_nearby:
		return
	
	if event.is_action_pressed("interact"):
		toggle_chest()
		get_viewport().set_input_as_handled()

func toggle_chest() -> void:
	if is_open:
		close_chest()
	else:
		open_chest()

func open_chest() -> void:
	if is_open:
		return
	
	is_open = true
	label_3d.visible = false
	
	if chest_inventory:
		chest_inventory.open(self)
	
	_set_target_angles(open_angle)

func close_chest() -> void:
	if not is_open:
		return
	
	is_open = false
	label_3d.visible = is_player_nearby
	
	if chest_inventory:
		chest_inventory.close()
	
	_set_target_angles(0.0)

func _set_target_angles(angle: float) -> void:
	var rad := deg_to_rad(angle)
	for i in range(animated_objects.size()):
		if animated_objects[i]:
			target_angles[i] = rad

func _on_chest_closed() -> void:
	close_chest()

func save_chest() -> Dictionary:
	var data := {}
	data["chest_id"] = chest_id
	data["is_open"] = is_open
	if chest_inventory:
		data["inventory"] = chest_inventory.save_inventory()
	return data

func load_chest(data: Dictionary) -> void:
	if data.has("is_open"):
		is_open = data["is_open"]
		_set_target_angles(open_angle if is_open else 0.0)
	
	if data.has("inventory") and chest_inventory:
		chest_inventory.load_inventory(data["inventory"])
