shader_type spatial;

uniform vec4 hologram_color = vec4(0.0, 0.6, 1.0, 1.0);
uniform float transparency : hint_range(0.0, 1.0) = 0.6;
uniform float glitch_strength : hint_range(0.0, 1.0) = 0.3;
uniform float glow_intensity : hint_range(0.0, 1.0) = 0.4;
uniform float time_factor : hint_range(0.0, 10.0) = 1.0;
uniform sampler2D texture_sampler;
uniform float noise_amount : hint_range(0.0, 1.0) = 0.05;
uniform float vertical_shift_speed : hint_range(-1.0, 1.0) = 0.1;

float random_noise(vec2 uv) {
    return fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
    vec2 uv = FRAGCOORD.xy / VIEWPORT_SIZE.xy;
    uv.y += TIME * vertical_shift_speed;
    float noise = random_noise(uv + TIME * 0.1);
    uv.x += noise * glitch_strength * 0.05;
    float glitch = sin(uv.x * 10.0 + TIME * time_factor) * glitch_strength;
    uv.x += glitch * 0.05;
    float glow = sin(TIME * 2.0) * glow_intensity;
    vec4 color = texture(texture_sampler, uv);
    color.rgb += glow * hologram_color.rgb * 0.5;
    color.r += sin(TIME + uv.y * 3.0) * 0.1 * glitch_strength;
    color.g += cos(TIME + uv.x * 2.0) * 0.1 * glitch_strength;
    color.rgb *= hologram_color.rgb;
    color.a *= transparency;
    color.rgb += random_noise(uv) * noise_amount;
    ALBEDO = color.rgb;
    ALPHA = color.a;
}
