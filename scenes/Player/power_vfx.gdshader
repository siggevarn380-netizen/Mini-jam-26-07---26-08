shader_type canvas_item;

uniform sampler2D noise_texture : repeat_enable;
uniform float scroll_speed : hint_range(-5.0, 5.0) = 0.5;
uniform float noise_scale : hint_range(0.1, 10.0) = 2.0;

// Color mapping
uniform vec4 bright_color : source_color = vec4(1.0, 0.8, 0.3, 1.0); // Bright core/highlights
uniform vec4 base_color : source_color = vec4(1.0, 0.3, 0.0, 1.0);   // Saturated background

// Controls how much the noise modulates opacity and brightness
uniform float min_brightness : hint_range(0.0, 1.0) = 0.5;

void fragment() {
	// 1. Center UVs
	vec2 centered_uv = UV - vec2(0.5);

	// 2. Polar transformation
	float dist = length(centered_uv);
	float angle = atan(centered_uv.y, centered_uv.x);

	// 3. Radial UVs
	vec2 polar_uv = vec2(dist * noise_scale - TIME * scroll_speed, (angle / (2.0 * PI)) + 0.5);

	// 4. Sample noise texture
	float raw_noise = texture(noise_texture, polar_uv).r;

	// 5. Remap noise from [0, 1] to [min_brightness, 1.0] to prevent black spots
	float clean_noise = mix(min_brightness, 1.0, raw_noise);

	// 6. Sample ring mask
	vec4 ring_tex = texture(TEXTURE, UV);
	float mask = ring_tex.a * ring_tex.r;

	// 7. Blend between base_color and bright_color based on noise
	vec3 final_rgb = mix(base_color.rgb, bright_color.rgb, raw_noise);
	
	// Apply mask and clamped alpha
	float final_alpha = mask * clean_noise * base_color.a;

	COLOR = vec4(final_rgb, final_alpha);
}