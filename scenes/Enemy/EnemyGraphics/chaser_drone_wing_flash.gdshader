shader_type canvas_item;

uniform vec4 flash_color : source_color = vec4(1.0, 0.0, 0.0, 1.0); // Red by default
uniform float flash_speed : hint_range(0.0, 30.0) = 15.0;            // Speed of blinking
uniform bool is_flashing = false;

//void vertex() {
	//// Called for every vertex the material is visible on.
//}

void fragment() {
    vec4 color = texture(TEXTURE, UV);
    
    if (is_flashing) {
        // Creates a value between 0.0 and 1.0 pulsing at flash_speed
        float blink = (sin(TIME * flash_speed) + 1.0) * 0.5;
        color.rgb = mix(color.rgb, flash_color.rgb, blink *blink);
    }
    
    COLOR = color;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
