@tool
extends Control

@export var icons: Array[TextureRect] = []  # Перетаскивай Icon сюда в инспекторе!

var current_slot: int = 0
const TOTAL_SLOTS: int = 4

func _ready():
	update_highlight()

func update_highlight():
	if icons.size() < TOTAL_SLOTS:
		push_warning("Не хватает иконок! Нужно: ", TOTAL_SLOTS)
		return
	
	for i in range(TOTAL_SLOTS):
		var icon = icons[i]
		if not icon: continue
		
		if i == current_slot:
			icon.modulate = Color(1.498, 1.495, 1.498, 1.0)  # Яркая подсветка
			icon.scale = Vector2(1.1, 1.1)        # Лёгкое увеличение
		else:
			icon.modulate = Color(0.7, 0.7, 0.7)  # Приглушённый
			icon.scale = Vector2(1.0, 1.0)        # Нормальный размер

func switch_slot(new_slot: int):
	if new_slot >= 0 and new_slot < TOTAL_SLOTS:
		current_slot = new_slot
		update_highlight()

func _input(event):
	if Engine.is_editor_hint(): return

	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1: switch_slot(0)
			KEY_2: switch_slot(1)
			KEY_3: switch_slot(2)
			KEY_4: switch_slot(3)

	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			switch_slot((current_slot - 1 + TOTAL_SLOTS) % TOTAL_SLOTS)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			switch_slot((current_slot + 1) % TOTAL_SLOTS)
