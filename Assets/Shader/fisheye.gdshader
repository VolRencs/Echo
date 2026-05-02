shader_type canvas_item;

// ═══════════════════════════════════════════════════════════════════════════════
//  CINEMATIC LENS — horror camera feel
//  Эффекты: линзовое дыхание + хром. аберрация (только края) +
//           виньетка + зернистость плёнки + цветокоррекция теней
// ═══════════════════════════════════════════════════════════════════════════════

// ── Линза ────────────────────────────────────────────────────────────────────
// Очень лёгкое бочкообразное искажение — без чёрных краёв
uniform float lens_distortion    : hint_range(0.0, 0.25) = 0.04;
// Камера чуть "дышит" — живой ощущение ручной съёмки
uniform float lens_breathe       : hint_range(0.0, 0.02) = 0.004;
uniform float breathe_speed      : hint_range(0.1, 3.0)  = 0.4;

// ── Хроматическая аберрация ──────────────────────────────────────────────────
// RGB расщепляется только у краёв как в настоящей оптике
uniform float chromatic_amount   : hint_range(0.0, 0.02) = 0.005;

// ── Виньетка ─────────────────────────────────────────────────────────────────
uniform float vignette_intensity : hint_range(0.0, 1.5)  = 0.45;
uniform float vignette_curve     : hint_range(0.5, 5.0)  = 2.2;

// ── Плёночное зерно ──────────────────────────────────────────────────────────
uniform float grain_amount       : hint_range(0.0, 0.12) = 0.032;
uniform float grain_speed        : hint_range(1.0, 30.0) = 18.0;

// ── Цветокоррекция ───────────────────────────────────────────────────────────
// Лёгкое обесцвечивание
uniform float saturation         : hint_range(0.0, 1.5)  = 0.88;
// Холодный оттенок в тенях (типичный хоррор)
uniform vec3  shadow_color       : source_color           = vec3(0.04, 0.07, 0.14);
uniform float shadow_tint        : hint_range(0.0, 0.6)  = 0.22;

// ── Системное ────────────────────────────────────────────────────────────────
uniform float aspect_ratio       : hint_range(0.1, 4.0)  = 1.777;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;

// ─── УТИЛИТЫ ──────────────────────────────────────────────────────────────────

// Линзовое искажение без выхода за [0,1]
vec2 distort(vec2 uv, float strength) {
	vec2 c = uv * 2.0 - 1.0;
	c.x *= aspect_ratio;
	c *= 1.0 - strength * dot(c, c);
	c.x /= aspect_ratio;
	return c * 0.5 + 0.5;
}

// Быстрый белый шум
float noise(vec2 co) {
	return fract(sin(dot(co, vec2(127.1, 311.7))) * 43758.5453);
}

// ─── ФРАГМЕНТ ─────────────────────────────────────────────────────────────────

void fragment() {
	// ── 1. Дыхание камеры ──────────────────────────────────────────────────
	float breathe = sin(TIME * breathe_speed) * lens_breathe;
	vec2 breathe_uv = (SCREEN_UV - 0.5) * (1.0 + breathe) + 0.5;

	// ── 2. Линзовое искажение ───────────────────────────────────────────────
	vec2 base_uv = distort(breathe_uv, lens_distortion);

	// ── 3. Хроматическая аберрация (только по краям) ───────────────────────
	//   Направление — от центра наружу, как в настоящей оптике
	vec2 edge_dir  = normalize(SCREEN_UV - 0.5 + vec2(0.00001));
	float edge_pow = dot(SCREEN_UV - 0.5, SCREEN_UV - 0.5) * 4.0; // 0=центр 1=край
	vec2 ca_offset = edge_dir * chromatic_amount * edge_pow;

	float r = texture(screen_texture, distort(breathe_uv + ca_offset,       lens_distortion)).r;
	float g = texture(screen_texture, base_uv).g;
	float b = texture(screen_texture, distort(breathe_uv - ca_offset * 0.7, lens_distortion)).b;

	vec3 col = vec3(r, g, b);

	// ── 4. Насыщенность ────────────────────────────────────────────────────
	float lum = dot(col, vec3(0.299, 0.587, 0.114));
	col = mix(vec3(lum), col, saturation);

	// ── 5. Цветокоррекция теней ────────────────────────────────────────────
	//   Тёмные участки смещаются в холодный оттенок
	float dark = clamp(1.0 - lum * 2.5, 0.0, 1.0);
	col = mix(col, col * (1.0 - shadow_tint) + shadow_color * shadow_tint, dark);

	// ── 6. Виньетка ────────────────────────────────────────────────────────
	float vig = dot(SCREEN_UV - 0.5, SCREEN_UV - 0.5) * 4.0;
	col *= 1.0 - pow(clamp(vig, 0.0, 1.0), vignette_curve) * vignette_intensity;

	// ── 7. Плёночное зерно ─────────────────────────────────────────────────
	//   Зерно чуть ярче в тенях — как настоящая плёнка
	float grain = (noise(SCREEN_UV + fract(TIME * grain_speed)) - 0.5) * grain_amount;
	grain *= 1.0 + (1.0 - lum) * 0.6;
	col += grain;

	COLOR = vec4(col, 1.0);
}
