@tool
extends Control

var slot_index: int = 0
var slot_data: InventorySlot = null
var icon: TextureRect = null

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	call_deferred("_init_icon")
	mouse_filter = Control.MOUSE_FILTER_PASS

func _init_icon() -> void:
	icon = get_node_or_null("Icon")
	if icon:
		print("Slot ", slot_index, ": Found Icon '", icon.name, "'")
	else:
		print("Slot ", slot_index, ": Icon child not found, searching...")
		for child in get_children():
			print("  Child: ", child.name, " (", child.get_class(), ")")
			if child is TextureRect:
				icon = child
				print("  -> Using ", child.name, " as icon")
				break
	
	if not icon:
		push_error("Slot ", slot_index, ": NO ICON FOUND!")

func set_slot_index(index: int) -> void:
	slot_index = index

func update_display(slot: InventorySlot) -> void:
	if Engine.is_editor_hint():
		return
	
	slot_data = slot
	
	if not icon:
		_init_icon()
		if not icon:
			return
	
	print("Slot ", slot_index, " update: empty=", slot.is_empty())
	
	if slot.is_empty():
		icon.texture = null
		modulate.a = 0.5
		print("  -> Cleared")
	else:
		icon.texture = slot.item.icon
		modulate.a = 1.0
		print("  -> Set texture: ", icon.texture != null)
	
	icon.visible = true

func _get_drag_data(_at_position: Vector2) -> Variant:
	if not slot_data or slot_data.is_empty():
		return null
	
	if not icon or not icon.texture:
		return null
	
	var preview := TextureRect.new()
	preview.texture = icon.texture
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.size = Vector2(64, 64)
	preview.modulate.a = 0.8
	set_drag_preview(preview)
	
	return {
		"source_slot": self,
		"slot_index": slot_index,
		"item": slot_data.item,
		"quantity": slot_data.quantity
	}

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not data is Dictionary:
		return false
	return data.has("item")

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if not data is Dictionary:
		return
	
	var source_slot: Control = data.get("source_slot")
	if not source_slot or source_slot == self:
		return
	
	var source_inv := _find_inventory(source_slot)
	var target_inv := _find_inventory(self)
	
	if not source_inv or not target_inv:
		print("ERROR: Inventory not found")
		return
	
	var source_data: InventorySlot = source_inv.get_slot(source_slot.slot_index)
	var target_data: InventorySlot = target_inv.get_slot(slot_index)
	
	if not source_data or source_data.is_empty():
		return
	
	if target_data.is_empty():
		target_data.item = source_data.item
		target_data.quantity = source_data.quantity
		source_data.clear()
	elif target_data.item.item_id == source_data.item.item_id:
		var space: int = target_data.item.max_stack - target_data.quantity
		var to_move: int = min(source_data.quantity, space)
		target_data.quantity += to_move
		source_data.quantity -= to_move
		if source_data.quantity <= 0:
			source_data.clear()
	else:
		var temp_item: ItemData = source_data.item
		var temp_qty: int = source_data.quantity
		source_data.item = target_data.item
		source_data.quantity = target_data.quantity
		target_data.item = temp_item
		target_data.quantity = temp_qty
	
	source_inv._update_slot_ui(source_slot.slot_index)
	target_inv._update_slot_ui(slot_index)

func _find_inventory(slot: Control) -> Node:
	var current := slot.get_parent()
	for _i in range(10):
		if not current:
			break
		if current.get_script():
			var script_path: String = current.get_script().resource_path
			if "InventoryManager" in script_path or "ChestInventory" in script_path:
				return current
		if current.has_method("get_slot") and current.has_method("_update_slot_ui"):
			return current
		current = current.get_parent()
	return null
