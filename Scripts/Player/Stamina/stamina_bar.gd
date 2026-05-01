@tool
class_name StaminaBar
extends Control

# ─── EXPORTS ──────────────────────────────────────────────────────────────────

@export_range(0.0, 1.0, 0.01) var value: float = 1.0:
	set(v):
		value = clampf(v, 0.0, 1.0)
		queue_redraw()

@export var smooth_speed: float = 7.0

# ─── ЦВЕТА ────────────────────────────────────────────────────────────────────

const C_FRAME_OUTER  := Color(0.10, 0.11, 0.12)
const C_FRAME_INNER  := Color(0.17, 0.19, 0.21)
const C_FRAME_EDGE   := Color(0.32, 0.36, 0.40)
const C_BG           := Color(0.030, 0.033, 0.038)
const C_BG_TRACK     := Color(0.055, 0.060, 0.068)

const C_CYAN         := Color(0.00, 0.88, 1.00)
const C_YELLOW       := Color(1.00, 0.72, 0.00)
const C_RED          := Color(0.85, 0.08, 0.04)
const C_RED_EMPTY    := Color(0.28, 0.02, 0.02)

# ─── СОСТОЯНИЕ ────────────────────────────────────────────────────────────────

var _vis: float = 1.0

# ─── PROCESS ──────────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if not is_equal_approx(_vis, value):
		_vis = lerpf(_vis, value, smooth_speed * delta)
		if absf(_vis - value) < 0.002:
			_vis = value
		queue_redraw()

# ─── ЦВЕТ ЗАПОЛНЕНИЯ ──────────────────────────────────────────────────────────

func _fill_color(v: float) -> Color:
	if v <= 0.0:   return C_RED_EMPTY
	if v <= 0.25:  return C_RED.lerp(C_YELLOW,  v / 0.25)
	if v <= 0.5:   return C_YELLOW.lerp(C_CYAN, (v - 0.25) / 0.25)
	return C_CYAN

# ─── DRAW ─────────────────────────────────────────────────────────────────────

func _draw() -> void:
	var W := size.x
	var H := size.y
	var col := _fill_color(_vis)

	# ── 1. Внешняя рамка ────────────────────────────────────────────────────
	_fill_rect(Rect2(0, 0, W, H), C_FRAME_OUTER)

	# ── 2. Внутренняя рамка (светлее) ───────────────────────────────────────
	var fr := 2.5
	_fill_rect(Rect2(fr, fr, W - fr * 2, H - fr * 2), C_FRAME_INNER)

	# ── 3. Фоновая дорожка ──────────────────────────────────────────────────
	var pad := fr + 3.5
	var track := Rect2(pad, pad, W - pad * 2, H - pad * 2)
	_fill_rect(track, C_BG)
	# Лёгкий градиент-полоска сверху дорожки
	_fill_rect(Rect2(track.position, Vector2(track.size.x, track.size.y * 0.3)), C_BG_TRACK)

	# ── 4. Заполнение бара ──────────────────────────────────────────────────
	if _vis > 0.001:
		var fill_w := track.size.x * _vis
		var fill := Rect2(track.position, Vector2(fill_w, track.size.y))

		# Свечение (4 слоя с убыванием прозрачности)
		for i in range(5, 0, -1):
			var g := float(i) * 1.8
			var glow := Rect2(fill.position - Vector2(g * 0.3, g),
							  fill.size     + Vector2(g * 0.6, g * 2))
			draw_rect(glow, Color(col.r, col.g, col.b, 0.055))

		# Основная полоса
		draw_rect(fill, col)

		# Блик сверху (светлая полоска по верхней трети)
		var shine := Rect2(fill.position, Vector2(fill.size.x, fill.size.y * 0.38))
		draw_rect(shine, Color(1.0, 1.0, 1.0, 0.18))

		# Диагональные засечки (технический узор поверх заливки)
		var notch_col := Color(0.0, 0.0, 0.0, 0.12)
		var step := track.size.y * 1.4
		var x := track.position.x + step * 0.5
		while x < fill.position.x + fill.size.x:
			var x1 := x
			var x2 := x + track.size.y * 0.6
			draw_line(
				Vector2(x1, track.position.y),
				Vector2(x2, track.position.y + track.size.y),
				notch_col, 1.5
			)
			x += step

	# ── 5. Вертикальные засечки-деления на всей дорожке ─────────────────────
	var div_col := Color(1.0, 1.0, 1.0, 0.045)
	var divs    := 20
	for i in range(1, divs):
		var nx := track.position.x + track.size.x * float(i) / float(divs)
		draw_line(Vector2(nx, track.position.y + 1),
				  Vector2(nx, track.position.y + track.size.y - 1),
				  div_col, 1.0)

	# ── 6. Тонкая яркая полоска по верхнему краю рамки ──────────────────────
	draw_line(Vector2(pad + 14, fr * 0.7),
			  Vector2(W - pad - 14, fr * 0.7),
			  Color(1.0, 1.0, 1.0, 0.10), 1.0)
	draw_line(Vector2(pad + 14, H - fr * 0.7),
			  Vector2(W - pad - 14, H - fr * 0.7),
			  Color(1.0, 1.0, 1.0, 0.04), 1.0)

	# ── 7. Декор: боковые «болты» слева ─────────────────────────────────────
	var bolt_col := C_FRAME_EDGE if _vis > 0.0 else Color(C_RED.r * 0.6, 0.0, 0.0)
	draw_rect(Rect2(-3.0, H * 0.18, 4.5, H * 0.26), bolt_col)
	draw_rect(Rect2(-3.0, H * 0.56, 4.5, H * 0.26), bolt_col)
	# Справа
	draw_rect(Rect2(W - 1.5, H * 0.25, 4.5, H * 0.50), bolt_col)

	# ── 8. Угловые срезы рамки (tech-chamfer) ───────────────────────────────
	var chm := H * 0.28
	# Верхний правый угол
	draw_line(Vector2(W - chm, 0),    Vector2(W, chm),        C_FRAME_EDGE, 1.5)
	# Нижний правый угол
	draw_line(Vector2(W - chm, H),    Vector2(W, H - chm),    C_FRAME_EDGE, 1.5)

	# ── 9. Таб «STAMINA» ────────────────────────────────────────────────────
	_draw_stamina_tab(col if _vis > 0.0 else C_RED, fr)

	# ── 10. Процент ─────────────────────────────────────────────────────────
	_draw_percent(W, H, col if _vis > 0.0 else C_RED, pad)

# ─── ВСПОМОГАТЕЛЬНЫЕ ──────────────────────────────────────────────────────────

func _fill_rect(rect: Rect2, color: Color) -> void:
	draw_rect(rect, color)

func _draw_stamina_tab(col: Color, fr: float) -> void:
	var font      := ThemeDB.fallback_font
	var font_size := 11
	var label     := "STAMINA"
	var tw        := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var tab_w     := tw + 18.0
	var tab_h     := fr + 14.0
	var ox        := fr + 8.0

	# Трапеция таба
	var pts := PackedVector2Array([
		Vector2(ox,              tab_h),
		Vector2(ox,              fr + 3),
		Vector2(ox + 4,          0),
		Vector2(ox + tab_w,      0),
		Vector2(ox + tab_w + 7,  tab_h),
	])
	draw_colored_polygon(pts, Color(col.r * 0.18, col.g * 0.18, col.b * 0.18))
	draw_polyline(pts, Color(col.r * 0.7, col.g * 0.7, col.b * 0.7), 1.0)

	# Текст
	draw_string(font,
		Vector2(ox + 9, tab_h - 3),
		label,
		HORIZONTAL_ALIGNMENT_LEFT, -1,
		font_size,
		Color(col.r, col.g, col.b, 0.95))

func _draw_percent(W: float, H: float, col: Color, pad: float) -> void:
	var font      := ThemeDB.fallback_font
	var font_size := int(H * 0.46)
	var pct_str   := "%d%%" % roundi(_vis * 100)
	var tw        := font.get_string_size(pct_str, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x

	# Тень
	draw_string(font,
		Vector2(W - pad - tw - 4 + 1, H * 0.5 + font_size * 0.36 + 1),
		pct_str, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size,
		Color(0, 0, 0, 0.5))

	# Основной текст
	draw_string(font,
		Vector2(W - pad - tw - 4, H * 0.5 + font_size * 0.36),
		pct_str, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size,
		col)
