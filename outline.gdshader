shader_type spatial;

uniform vec3 scale = vec3(2.0);
uniform float width: hint_range(0.0, 10.0) = 0.25;
uniform float sharpness: hint_range(0.0, 1.0) = 0.5;
//uniform float glow: hint_range(1.0, 16.0) = 4.0;
//uniform vec4 color: hint_color = vec4(1.0);
//uniform sampler2D tex: hint_albedo;

varying vec3 vert;

void vertex() {
	vert = VERTEX;
}

void fragment() {
	vec3 fv = fract(vec3(vert.x, vert.y * -1.0, vert.z));
	vec3 vs = abs(vert) - scale * 0.5;
	float ws = width * sharpness;
	float value = (1.0 - smoothstep(ws, width, length(vs.xy)) * smoothstep(ws, width, length(vs.yz)) * smoothstep(ws, width, length(vs.xz)));
	
	ALBEDO = vec3(0.0);
	ALPHA = value;
	EMISSION = vec3(0.0);
}
