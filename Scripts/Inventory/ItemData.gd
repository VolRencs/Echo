extends Resource
class_name ItemData

@export var item_id: String = ""
@export var item_name: String = ""
@export var icon: Texture2D = null
@export var max_stack: int = 1
@export var description: String = ""

func duplicate_item() -> ItemData:
	var item := ItemData.new()
	item.item_id = item_id
	item.item_name = item_name
	item.icon = icon
	item.max_stack = max_stack
	item.description = description
	return item
