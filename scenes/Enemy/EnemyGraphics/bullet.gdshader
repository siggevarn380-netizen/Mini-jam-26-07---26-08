shader_type canvas_item;

// Color settings
uniform vec4 base_color : source_color = vec4(1.0, 0.3, 0.1, 1.0);
uniform vec4 wave_color : source_color = vec4(1.0, 0.9, 0.2, 1.0);

// Distortion settings
uniform sampler2D noise_texture : repeat_enable;
uniform float wave_speed : hint_range(0.0, 10.0) = 2.0;
uniform float wave_amplitude : hint_range(0.0, 50.0) = 8.0;
uniform float noise_scale : hint_range(0.1, 5.0) = 1.0;

void vertex() {
	// Sample the noise texture using vertex X position and time
	vec2 noise_uv = vec2(VERTEX.x * 0.01 * noise_scale + TIME * wave_speed, 0.5);
	float noise_val = texture(noise_texture, noise_uv).r * 2.0 - 1.0; // Scale to [-1, 1]
	
	// Apply displacement vertically
	VERTEX.y += noise_val * wave_amplitude;
}

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	
	// Sample noise for color blending across the UV map
	vec2 color_noise_uv = UV * noise_scale + vec2(TIME * wave_speed * 0.5, 0.0);
	float noise_val = texture(noise_texture, color_noise_uv).r;
	
	// Mix base color with wave color based on noise intensity
	vec4 final_color = mix(base_color, wave_color, noise_val);
	
	// Maintain the original texture's transparency
	COLOR = vec4(final_color.rgb, tex_color.a * final_color.a * pow(1.3 - tex_color.r, 2.0));
}