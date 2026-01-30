@tool
extends Control
class_name InventoryManager

@export var slot_container: HBoxContainer
@export var slot_scene: PackedScene

const TOTAL_SLOTS := 4
const SELECTED_COLOR := Color(1.3, 1.3, 1.5, 1.0)
const NORMAL_COLOR := Color(0.75, 0.75, 0.75, 1.0)
const SELECTED_SCALE := Vector2(1.15, 1.15)
const NORMAL_SCALE := Vector2.ONE

var current_slot: int = 0
var slots: Array[InventorySlot] = []
var slot_ui: Array[Control] = []

signal slot_changed(slot_index: int, slot: InventorySlot)
signal selected_slot_changed(new_slot: int)

func _ready() -> void:
	_initialize_slots()
	if not Engine.is_editor_hint():
		call_deferred("update_highlight")

func _initialize_slots() -> void:
	slots.clear()
	slot_ui.clear()
	
	for i in range(TOTAL_SLOTS):
		slots.append(InventorySlot.new())
	
	if slot_container:
		var existing_slots := slot_container.get_children()
		if existing_slots.size() >= TOTAL_SLOTS:
			for i in range(TOTAL_SLOTS):
				var slot_control: Control = existing_slots[i] as Control
				if slot_control:
					slot_ui.append(slot_control)
					_setup_slot_ui(slot_control, i)
			return
		
		for child in existing_slots:
			child.queue_free()
		
		if slot_scene:
			for i in range(TOTAL_SLOTS):
				var slot_control: Control = slot_scene.instantiate() as Control
				slot_container.add_child(slot_control)
				slot_ui.append(slot_control)
				_setup_slot_ui(slot_control, i)

func _setup_slot_ui(slot_control: Control, index: int) -> void:
	if slot_control.has_method("set_slot_index"):
		slot_control.set_slot_index(index)
	
	if slot_control.has_signal("slot_clicked"):
		if not slot_control.slot_clicked.is_connected(_on_slot_clicked):
			slot_control.slot_clicked.connect(_on_slot_clicked.bind(index))

func update_highlight() -> void:
	for i in range(min(slot_ui.size(), TOTAL_SLOTS)):
		var ui: Control = slot_ui[i]
		if not is_instance_valid(ui):
			continue
		
		var selected: bool = (i == current_slot)
		ui.modulate = SELECTED_COLOR if selected else NORMAL_COLOR
		ui.scale = SELECTED_SCALE if selected else NORMAL_SCALE

func switch_slot(new_slot: int) -> void:
	if new_slot == current_slot:
		return
	if new_slot not in range(TOTAL_SLOTS):
		return
	
	current_slot = new_slot
	update_highlight()
	selected_slot_changed.emit(current_slot)

func get_current_slot() -> InventorySlot:
	if current_slot < slots.size():
		return slots[current_slot]
	return null

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

func _on_slot_clicked(index: int) -> void:
	switch_slot(index)

func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	
	if event is InputEventKey and event.is_pressed() and not event.echo:
		var slot: int = event.keycode - KEY_1
		if slot in range(TOTAL_SLOTS):
			switch_slot(slot)
	elif event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP:
				switch_slot((current_slot - 1 + TOTAL_SLOTS) % TOTAL_SLOTS)
			MOUSE_BUTTON_WHEEL_DOWN:
				switch_slot((current_slot + 1) % TOTAL_SLOTS)

func save_inventory() -> Dictionary:
	var data: Dictionary = {}
	data["current_slot"] = current_slot
	data["slots"] = []
	
	for slot in slots:
		var slot_data: Dictionary = {}
		if not slot.is_empty():
			slot_data["item_id"] = slot.item.item_id
			slot_data["quantity"] = slot.quantity
		data["slots"].append(slot_data)
	
	return data

func load_inventory(data: Dictionary) -> void:
	if data.has("current_slot"):
		current_slot = data["current_slot"]
	
	if data.has("slots"):
		for i in range(min(data["slots"].size(), slots.size())):
			var slot_data: Dictionary = data["slots"][i]
			if slot_data.is_empty():
				slots[i].clear()
			else:
				pass
			_update_slot_ui(i)
	
	update_highlight()
