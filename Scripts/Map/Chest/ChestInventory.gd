extends Control
class_name ChestInventory

@export var slot_container: GridContainer
@export var slot_scene: PackedScene
@export var close_button: Button
@export var chest_slots: int = 12

var is_open := false
var slots: Array[InventorySlot] = []
var slot_ui: Array[Control] = []
var current_chest: Chest = null

signal chest_closed
signal slot_changed(slot_index: int, slot: InventorySlot)

func _ready() -> void:
	visible = false
	_initialize_slots()
	
	if close_button:
		close_button.pressed.connect(close)

func _initialize_slots() -> void:
	slots.clear()
	slot_ui.clear()
	
	for i in range(chest_slots):
		slots.append(InventorySlot.new())
	
	if not slot_container:
		return
	
	var existing_slots: Array = []
	for child in slot_container.get_children():
		if child is Control:
			existing_slots.append(child)
	
	if existing_slots.size() >= chest_slots:
		print("ChestInventory: Using existing slots from scene")
		for i in range(chest_slots):
			var slot_control: Control = existing_slots[i] as Control
			if slot_control:
				if not slot_control.get_script():
					var script_path: String = "res://SlotUI.gd"
					if not FileAccess.file_exists(script_path):
						script_path = "res://Scripts/SlotUI.gd"
					if not FileAccess.file_exists(script_path):
						script_path = "res://Scenes/UI/SlotUI.gd"
					
					if FileAccess.file_exists(script_path):
						var script: Script = load(script_path)
						if script:
							slot_control.set_script(script)
				
				slot_ui.append(slot_control)
				if slot_control.has_method("set_slot_index"):
					slot_control.set_slot_index(i)
		return
	
	for child in existing_slots:
		child.queue_free()
	
	if slot_scene:
		for i in range(chest_slots):
			var slot_control: Control = slot_scene.instantiate() as Control
			slot_container.add_child(slot_control)
			slot_ui.append(slot_control)
			_setup_slot_ui(slot_control, i)

func _setup_slot_ui(slot_control: Control, index: int) -> void:
	if slot_control.has_method("set_slot_index"):
		slot_control.set_slot_index(index)
	
	if slot_control.has_signal("slot_clicked"):
		slot_control.slot_clicked.connect(_on_slot_clicked.bind(index))

func open(chest: Chest) -> void:
	current_chest = chest
	visible = true
	is_open = true
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	_update_all_slots()

func close() -> void:
	visible = false
	is_open = false
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	current_chest = null
	chest_closed.emit()

func get_slot(index: int) -> InventorySlot:
	if index in range(slots.size()):
		return slots[index]
	return null

func add_item(item: ItemData, quantity: int = 1) -> int:
	var remaining: int = quantity
	
	for i in range(slots.size()):
		if remaining <= 0:
			break
		
		if not slots[i].is_empty() and slots[i].item.item_id == item.item_id:
			remaining = slots[i].add_item(item, remaining)
			_update_slot_ui(i)
			slot_changed.emit(i, slots[i])
	
	for i in range(slots.size()):
		if remaining <= 0:
			break
		
		if slots[i].is_empty():
			remaining = slots[i].add_item(item, remaining)
			_update_slot_ui(i)
			slot_changed.emit(i, slots[i])
	
	return remaining

func remove_item(item_id: String, quantity: int = 1) -> int:
	var remaining: int = quantity
	
	for i in range(slots.size()):
		if remaining <= 0:
			break
		
		if not slots[i].is_empty() and slots[i].item.item_id == item_id:
			var removed: int = slots[i].remove_item(remaining)
			remaining -= removed
			_update_slot_ui(i)
			slot_changed.emit(i, slots[i])
	
	return quantity - remaining

func has_item(item_id: String, quantity: int = 1) -> bool:
	var total: int = 0
	for slot in slots:
		if not slot.is_empty() and slot.item.item_id == item_id:
			total += slot.quantity
			if total >= quantity:
				return true
	return false

func _update_slot_ui(index: int) -> void:
	if index >= slot_ui.size():
		return
	
	var ui: Control = slot_ui[index]
	var slot: InventorySlot = slots[index]
	
	if not is_instance_valid(ui):
		return
	
	if ui.has_method("update_display"):
		ui.update_display(slot)

func _update_all_slots() -> void:
	for i in range(slots.size()):
		_update_slot_ui(i)

func _on_slot_clicked(_index: int) -> void:
	pass

func _input(event: InputEvent) -> void:
	if not is_open:
		return
	
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("interact"):
		close()
		get_viewport().set_input_as_handled()

func save_inventory() -> Dictionary:
	var data: Dictionary = {}
	data["slots"] = []
	
	for slot in slots:
		var slot_data: Dictionary = {}
		if not slot.is_empty():
			slot_data["item_id"] = slot.item.item_id
			slot_data["quantity"] = slot.quantity
		data["slots"].append(slot_data)
	
	return data

func load_inventory(data: Dictionary) -> void:
	if not data.has("slots"):
		return
	
	for i in range(min(data["slots"].size(), slots.size())):
		var slot_data: Dictionary = data["slots"][i]
		if slot_data.is_empty():
			slots[i].clear()
		else:
			pass
		_update_slot_ui(i)
