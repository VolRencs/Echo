extends Node

@export var player_inventory: InventoryManager

func _ready() -> void:
	await get_tree().create_timer(0.5).timeout
	_add_test_item()

func _add_test_item() -> void:
	var test_item: ItemData = ItemData.new()
	test_item.item_id = "test_item"
	test_item.item_name = "Test Item"
	test_item.max_stack = 64
	test_item.description = "A test item"
	test_item.icon = _create_test_texture()
	
	if player_inventory:
		var remaining: int = player_inventory.add_item(test_item, 5)
		if remaining == 0:
			print("Successfully added 5 test items to inventory!")
		else:
			print("Added items, but ", remaining, " couldn't fit")

func _create_test_texture() -> ImageTexture:
	var img: Image = Image.create(64, 64, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.3, 0.6, 1.0, 1.0))
	return ImageTexture.create_from_image(img)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_text_backspace"):
		_add_test_item()
		print("Added more test items!")
