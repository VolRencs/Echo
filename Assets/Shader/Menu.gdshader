shader_type canvas_item;
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float blur_size : hint_range(0.0, 2.0) = 2.0;
uniform int iterations : hint_range(1, 10) = 2;
uniform float opacity : hint_range(0.0, 1.0) = 0.8;

void fragment() {
    vec2 uv = SCREEN_UV;
    vec2 pixel = 1.0 / vec2(textureSize(SCREEN_TEXTURE, 0));
    vec4 color = vec4(0.0);
    float total_weight = 0.0;

    float weights[4] = float[](
        0.4,
        0.3,
        0.2,
        0.1 
    );

    color += texture(SCREEN_TEXTURE, uv) * weights[0];
    total_weight += weights[0];

    for (int i = 1; i <= iterations; i++) {
        float offset = blur_size * float(i);
        float weight = (i <= 2) ? weights[i] : 0.05;

        color += texture(SCREEN_TEXTURE, uv + vec2(offset, 0.0) * pixel) * weight;
        color += texture(SCREEN_TEXTURE, uv - vec2(offset, 0.0) * pixel) * weight;
        color += texture(SCREEN_TEXTURE, uv + vec2(0.0, offset) * pixel) * weight;
        color += texture(SCREEN_TEXTURE, uv - vec2(0.0, offset) * pixel) * weight;
        total_weight += 4.0 * weight;

    }

    COLOR = vec4(color.rgb / total_weight, opacity);
}
