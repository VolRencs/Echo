shader_type canvas_item;

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float blur_size : hint_range(0.0, 10.0) = 2.0;
uniform int iterations : hint_range(1, 8) = 4;
uniform float opacity : hint_range(0.0, 1.0) = 0.8;

void fragment() {
    vec4 color = vec4(0.0);
    float total_samples = 0.0;

    for (int i = 1; i <= iterations; i++) {
        float offset = blur_size * float(i);
        vec2 offset_vec = vec2(offset) * TEXTURE_PIXEL_SIZE.xy;
        
        color += texture(SCREEN_TEXTURE, SCREEN_UV + offset_vec);
        color += texture(SCREEN_TEXTURE, SCREEN_UV - vec2(offset_vec.x, -offset_vec.y));
        color += texture(SCREEN_TEXTURE, SCREEN_UV - offset_vec);
        color += texture(SCREEN_TEXTURE, SCREEN_UV + vec2(offset_vec.x, -offset_vec.y));
        
        total_samples += 4.0;
    }
    
    color /= total_samples;
    COLOR = vec4(color.rgb, opacity);
}
