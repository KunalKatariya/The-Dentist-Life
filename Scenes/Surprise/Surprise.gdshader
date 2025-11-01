shader_type canvas_item;

uniform vec2 circle_pos = vec2(400.0, 300.0); // pixel position of the circle
uniform float radius = 100.0; // radius of visible area
uniform float feather = 20.0; // smooth edge of circle

void fragment() {
    vec2 uv = FRAGCOORD.xy; // pixel coordinates
    float dist = distance(uv, circle_pos);

    // Invert the alpha: fully opaque everywhere except inside the circle
    float alpha = 1.0 - smoothstep(radius - feather, radius, dist);

    COLOR = vec4(0.0, 0.0, 0.0, alpha);
}
