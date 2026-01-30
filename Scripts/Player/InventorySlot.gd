extends Resource
class_name InventorySlot

var item: ItemData = null
var quantity: int = 0

func is_empty() -> bool:
	return item == null or quantity <= 0

func can_add_item(new_item: ItemData, amount: int = 1) -> bool:
	if is_empty():
		return true
	if item.item_id == new_item.item_id:
		return quantity + amount <= item.max_stack
	return false

func add_item(new_item: ItemData, amount: int = 1) -> int:
	if is_empty():
		item = new_item
		quantity = min(amount, new_item.max_stack)
		return amount - quantity
	
	if item.item_id == new_item.item_id:
		var space: int = item.max_stack - quantity
		var add_amount: int = min(amount, space)
		quantity += add_amount
		return amount - add_amount
	
	return amount

func remove_item(amount: int = 1) -> int:
	var removed: int = min(amount, quantity)
	quantity -= removed
	
	if quantity <= 0:
		item = null
		quantity = 0
	
	return removed

func clear() -> void:
	item = null
	quantity = 0

func duplicate_slot() -> InventorySlot:
	var slot: InventorySlot = InventorySlot.new()
	if item:
		slot.item = item.duplicate_item()
	slot.quantity = quantity
	return slot
