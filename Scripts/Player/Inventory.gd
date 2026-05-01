@tool
class_name InventoryBar
extends Control

@export_range(1, 8, 1) var slot_count: int = 5:
	set(v):
		slot_count = v
		_items.resize(slot_count)
		queue_redraw()

@export_range(0, 7, 1) var active_slot: int = 0:
	set(v):
		active_slot = clamp(v, 0, slot_count - 1)
		queue_redraw()

@export var slot_size: float = 72.0:
	set(v):
		slot_size = v
		_update_min_size()
		queue_redraw()

@export var pulse_speed: float = 2.8

const C_FRAME_OUTER  := Color(0.09, 0.10, 0.11)
const C_FRAME_INNER  := Color(0.15, 0.17, 0.19)
const C_FRAME_EDGE   := Color(0.30, 0.34, 0.38)
const C_SLOT_BG      := Color(0.025, 0.028, 0.033)
const C_SLOT_TRACK   := Color(0.050, 0.055, 0.065)
const C_DIVIDER      := Color(1.0, 1.0, 1.0, 0.035)
const C_CYAN         := Color(0.00, 0.88, 1.00)
const C_CYAN_DIM     := Color(0.00, 0.40, 0.48)
const C_EMPTY_ICON   := Color(0.18, 0.22, 0.26)

const PAD  := 8.0
const GAP  := 6.0
const CHM  := 6.0

var _items: Array[Texture2D] = []
var _pulse_t: float = 0.0

func _ready() -> void:
	_items.resize(slot_count)
	_update_min_size()

func _update_min_size() -> void:
	custom_minimum_size = Vector2(
		slot_count * (slot_size + GAP) - GAP + PAD * 2,
		slot_size + PAD * 2
	)

func _process(delta: float) -> void:
	_pulse_t += delta * pulse_speed
	queue_redraw()

func set_item_icon(slot: int, tex: Texture2D) -> void:
	if slot >= 0 and slot < slot_count:
		_items[slot] = tex
		queue_redraw()

func clear_slot(slot: int) -> void:
	set_item_icon(slot, null)

func select_slot(slot: int) -> void:
	active_slot = slot

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		for i in range(min(slot_count, 9)):
			if event.keycode == KEY_1 + i:
				active_slot = i

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			active_slot = (active_slot - 1 + slot_count) % slot_count
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			active_slot = (active_slot + 1) % slot_count

func _draw() -> void:
	_update_min_size()
	var W := size.x
	var H := size.y

	var panel := PackedVector2Array([
		Vector2(CHM,     0),
		Vector2(W - CHM, 0),
		Vector2(W,       CHM),
		Vector2(W,       H - CHM),
		Vector2(W - CHM, H),
		Vector2(CHM,     H),
		Vector2(0,       H - CHM),
		Vector2(0,       CHM),
	])
	draw_colored_polygon(panel, C_FRAME_OUTER)
	draw_polyline(panel + PackedVector2Array([panel[0]]), C_FRAME_EDGE, 1.0)

	var fr := 2.5
	draw_rect(Rect2(fr, fr, W - fr * 2, H - fr * 2), C_FRAME_INNER)

	draw_line(Vector2(PAD + 10, fr * 0.6),     Vector2(W - PAD - 10, fr * 0.6),     Color(1, 1, 1, 0.09), 1.0)
	draw_line(Vector2(PAD + 10, H - fr * 0.6), Vector2(W - PAD - 10, H - fr * 0.6), Color(1, 1, 1, 0.04), 1.0)

	for i in range(slot_count):
		_draw_slot(i)

	draw_rect(Rect2(-3.0, H * 0.20, 4.5, H * 0.25), C_FRAME_EDGE)
	draw_rect(Rect2(-3.0, H * 0.55, 4.5, H * 0.25), C_FRAME_EDGE)
	draw_rect(Rect2(W - 1.5, H * 0.25, 4.5, H * 0.50), C_FRAME_EDGE)

func _draw_slot(idx: int) -> void:
	var is_active := (idx == active_slot)
	var sx := PAD + idx * (slot_size + GAP)
	var sy := PAD
	var slot_rect := Rect2(sx, sy, slot_size, slot_size)

	draw_rect(slot_rect, C_SLOT_BG)
	draw_rect(Rect2(sx, sy, slot_size, slot_size * 0.25), C_SLOT_TRACK)

	if is_active:
		var pulse := 0.5 + 0.5 * sin(_pulse_t)
		for layer in range(5, 0, -1):
			var g := float(layer) * 2.2
			var alpha := pulse * 0.06 * float(layer) / 5.0
			draw_rect(Rect2(slot_rect.position - Vector2(g, g), slot_rect.size + Vector2(g * 2, g * 2)),
					  Color(C_CYAN.r, C_CYAN.g, C_CYAN.b, alpha))

	var border_col: Color
	if is_active:
		var pulse2 := 0.7 + 0.3 * sin(_pulse_t)
		border_col = Color(C_CYAN.r, C_CYAN.g, C_CYAN.b, pulse2)
	else:
		border_col = Color(C_CYAN_DIM.r, C_CYAN_DIM.g, C_CYAN_DIM.b, 0.55)
	draw_rect(slot_rect, border_col, false, 1.2)

	if is_active:
		var chm2 := 5.0
		draw_line(Vector2(sx,                    sy + chm2),            Vector2(sx + chm2,          sy),                     border_col, 1.5)
		draw_line(Vector2(sx + slot_size - chm2, sy),                   Vector2(sx + slot_size,      sy + chm2),              border_col, 1.5)
		draw_line(Vector2(sx,                    sy + slot_size - chm2), Vector2(sx + chm2,          sy + slot_size),         border_col, 1.5)
		draw_line(Vector2(sx + slot_size - chm2, sy + slot_size),       Vector2(sx + slot_size,      sy + slot_size - chm2), border_col, 1.5)

	var icon_pad  := 8.0
	var icon_rect := Rect2(sx + icon_pad, sy + icon_pad, slot_size - icon_pad * 2, slot_size - icon_pad * 2)
	var icon_tex: Texture2D = _items[idx] if idx < _items.size() else null

	if icon_tex:
		draw_texture_rect(icon_tex, icon_rect, false)
		draw_rect(Rect2(icon_rect.position, Vector2(icon_rect.size.x, icon_rect.size.y * 0.35)), Color(1, 1, 1, 0.07))
	else:
		var cx  := sx + slot_size * 0.5
		var cy  := sy + slot_size * 0.5
		var arm := slot_size * 0.14
		var cross_col := C_EMPTY_ICON if not is_active else Color(C_CYAN.r, C_CYAN.g, C_CYAN.b, 0.25)
		draw_line(Vector2(cx - arm, cy), Vector2(cx + arm, cy), cross_col, 1.0)
		draw_line(Vector2(cx, cy - arm), Vector2(cx, cy + arm), cross_col, 1.0)

	var font      := ThemeDB.fallback_font
	var font_size := 9
	var num_str   := str(idx + 1)
	var num_col   := Color(C_CYAN.r, C_CYAN.g, C_CYAN.b, 0.9) if is_active else Color(0.45, 0.50, 0.55, 0.8)
	draw_string(font, Vector2(sx + 5 + 1, sy + slot_size - 5 + 1), num_str, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0, 0, 0, 0.5))
	draw_string(font, Vector2(sx + 5,     sy + slot_size - 5),     num_str, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, num_col)

	var step := slot_size * 0.55
	var x    := sx + step * 0.3
	while x < sx + slot_size:
		draw_line(Vector2(x, sy), Vector2(x + slot_size * 0.22, sy + slot_size), Color(0, 0, 0, 0.10), 1.0)
		x += step

	if idx < slot_count - 1:
		var dx := sx + slot_size + GAP * 0.5
		draw_line(Vector2(dx, PAD + 4), Vector2(dx, PAD + slot_size - 4), C_DIVIDER, 1.0)
