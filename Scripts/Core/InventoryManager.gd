@tool
extends Control

@export var icons: Array[TextureRect] = []

const TOTAL_SLOTS := 4
const SELECTED_COLOR := Color(1.3, 1.3, 1.5, 1.0)
const NORMAL_COLOR := Color(0.75, 0.75, 0.75, 1.0)
const SELECTED_SCALE := Vector2(1.15, 1.15)
const NORMAL_SCALE := Vector2.ONE

var current_slot: int = 0

func _ready() -> void:
	call_deferred("_init_inventory")

func _init_inventory() -> void:
	if icons.size() < TOTAL_SLOTS:
		push_warning("Недостаточно иконок (нужно %d, есть %d)" % [TOTAL_SLOTS, icons.size()])
		return
	
	for i in range(TOTAL_SLOTS):
		if not is_instance_valid(icons[i]):
			push_warning("Иконка слота %d не назначена или повреждена!" % (i + 1))
			return
	
	call_deferred("update_highlight")

func update_highlight() -> void:
	for i in range(min(icons.size(), TOTAL_SLOTS)):
		var icon := icons[i]
		if not is_instance_valid(icon):
			continue
		
		var selected := (i == current_slot)
		icon.modulate = SELECTED_COLOR if selected else NORMAL_COLOR
		icon.scale = SELECTED_SCALE if selected else NORMAL_SCALE

func switch_slot(new_slot: int) -> void:
	if new_slot == current_slot:
		return
	if new_slot in range(TOTAL_SLOTS):
		current_slot = new_slot
		update_highlight()

func _input(event: InputEvent) -> void:
	if Engine.is_editor_hint():
		return
	
	if event is InputEventKey and event.pressed:
		var slot: int = event.keycode - KEY_1
		if slot in range(TOTAL_SLOTS):
			switch_slot(slot)
	elif event is InputEventMouseButton and event.pressed:
		match event.button_index:
			MOUSE_BUTTON_WHEEL_UP: switch_slot((current_slot - 1 + TOTAL_SLOTS) % TOTAL_SLOTS)
			MOUSE_BUTTON_WHEEL_DOWN: switch_slot((current_slot + 1) % TOTAL_SLOTS)
