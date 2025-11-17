shader_type canvas_item;

uniform vec2 center = vec2(0.5, 0.5);
uniform float radius = 0.5;

void fragment() {
    // Calculate distance from center
    vec2 uv = UV - center;
    float dist = length(uv);
    
    // Clip to circle
    if (dist > radius) {
        COLOR.a = 0.0;
    }
}
void vertex() {
	// Called for every vertex the material is visible on.
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
