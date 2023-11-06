shader_type spatial;

uniform sampler3D mountainNoise;
uniform sampler2D clipNoise;
uniform sampler2D hillNoise;
uniform sampler2D hillNoiseNormal;

varying vec2 tex_pos;

void vertex() {
	// Place fragment code here.
	tex_pos = VERTEX.xz / 4.0;
	VERTEX.y = 0.4 * texture(hillNoise, tex_pos).r;
}

void fragment() {
	NORMAL_MAP = texture(hillNoiseNormal, tex_pos).xyz;
}