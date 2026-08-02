shader_type canvas_item;

uniform sampler2D noise_texture : repeat_enable;
uniform float progress : hint_range(0.0, 1.0) = 0.0; // Animate from 0.0 to 1.0

// Colors
uniform vec4 core_color : source_color = vec4(1.0, 0.9, 0.4, 1.0);
uniform vec4 edge_color : source_color = vec4(1.0, 0.2, 0.0, 1.0);

// Expansion Bounds
uniform float max_radius : hint_range(0.1, 0.5) = 0.25; // Expands outward up to 0.25
uniform float ring_thickness : hint_range(0.01, 0.3) = 0.08;

// Alpha Dissolve / Clip controls
uniform float clip_threshold : hint_range(0.0, 1.0) = 0.2; // Higher values erode more
uniform float edge_softness : hint_range(0.001, 0.2) = 0.05;

void fragment() {
	// 1. Center UVs [-0.5, 0.5]
	vec2 centered_uv = UV - vec2(0.5);
	float dist = length(centered_uv);
	float angle = atan(centered_uv.y, centered_uv.x);

	// 2. Polar UV mapping for continuous scrolling noise
	vec2 polar_uv = vec2(dist * 4.0 - progress * 3.0, (angle / (2.0 * PI)) + 0.5);
	float noise = texture(noise_texture, polar_uv).r;

	// 3. Expand the ring from center up to max_radius (0.25)
	float current_radius = mix(0.0, max_radius, progress);
	float ring = smoothstep(ring_thickness, 0.0, abs(dist - current_radius));

	// 4. Sample base ring texture mask
	vec4 base_tex = texture(TEXTURE, UV);
	float mask = base_tex.a * base_tex.r;

	// 5. Fade out over time
	float fade_out = smoothstep(1.0, 0.6, progress);

	// 6. Noise Alpha Clipping (Erodes the circular shape into broken fragments)
	// Increasing dissolve progress over time makes it break apart as it expands
	float dissolve_cutoff = mix(clip_threshold, 1.0, progress * 0.7);
	float noise_clip = smoothstep(dissolve_cutoff - edge_softness, dissolve_cutoff + edge_softness, noise * ring);

	// 7. Final RGB and Alpha blend
	vec3 color = mix(edge_color.rgb, core_color.rgb, noise);
	float final_alpha = mask * noise_clip * fade_out * mix(edge_color.a, core_color.a, noise);

	COLOR = vec4(color, final_alpha);
}