shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float blur_size : hint_range(0.0, 10.0) = 2.0; // Интенсивность размытия
uniform int iterations : hint_range(1, 8) = 4; // Количество итераций
uniform float opacity : hint_range(0.0, 1.0) = 0.8; // Прозрачность фона

void fragment() {
    vec4 color = vec4(0.0);
    float total = 0.0;
    
    // Kawase Blur (многопроходное размытие)
    for (int i = 0; i < iterations; i++) {
        float offset = blur_size * float(i + 1) * TEXTURE_PIXEL_SIZE.x;
        color += texture(SCREEN_TEXTURE, SCREEN_UV + vec2(offset, offset));
        color += texture(SCREEN_TEXTURE, SCREEN_UV + vec2(-offset, offset));
        color += texture(SCREEN_TEXTURE, SCREEN_UV + vec2(offset, -offset));
        color += texture(SCREEN_TEXTURE, SCREEN_UV + vec2(-offset, -offset));
        total += 4.0;
    }
    color /= total;
    
    // Применяем прозрачность
    COLOR = vec4(color.rgb, opacity);
}