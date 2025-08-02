shader_type spatial;

// This uniform will be fed the object's original texture by our script.
uniform sampler2D object_texture : source_color;
// This uniform controls the highlight color.
uniform vec4 highlight_color : source_color = vec4(1.0, 1.0, 0.0, 1.0); // Default Yellow

void fragment() {
	// Draw the object with its original texture.
	ALBEDO = texture(object_texture, UV).rgb;
	
	// Make the object glow with the highlight color.
	// This adds the highlight color on top of the albedo.
	EMISSION = highlight_color.rgb;
}