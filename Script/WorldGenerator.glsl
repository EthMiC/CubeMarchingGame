#[compute]
#version 450

layout(local_size_x = 4, local_size_y = 4, local_size_z = 4) in;

layout(set = 0, binding = 0, rgba8) uniform image2D TEXTURES[204];

layout(set = 1, binding = 0) coherent buffer InformationBuffer {
    float y_val;
    float airTreshold;
    float hillScale;
    float clipScale;
    float hillOffset;
    float clipOffset;
}
information_buffer;

void main() {
    // information
    vec4 color = vec4(0.0, 0.0, 0.0, 1.0);
    ivec2 texel1 = ivec2(gl_GlobalInvocationID.xy);
    ivec2 texel2 = ivec2(gl_GlobalInvocationID.xy + vec2(1, 0));
    ivec2 texel3 = ivec2(gl_GlobalInvocationID.xy + vec2(0, 1));
    ivec2 texel4 = ivec2(gl_GlobalInvocationID.xy - vec2(1, 0));
    ivec2 texel5 = ivec2(gl_GlobalInvocationID.xy - vec2(0, 1));

    float hillval1 = 0;
    float hillval2 = 0;
    float hillval3 = 0;
    float hillval4 = 0;
    float hillval5 = 0;
    float hillval6 = 0;
    float hillval7 = 0;
    
    float mountainval1 = 0;
    float mountainval2 = 0;
    float mountainval3 = 0;
    float mountainval4 = 0;
    float mountainval5 = 0;
    float mountainval6 = 0;
    float mountainval7 = 0;

    float val1 = 0;
    float val2 = 0;
    float val3 = 0;
    float val4 = 0;
    float val5 = 0;
    float val6 = 0;
    float val7 = 0;

    //update buffer textures

    //var hillNoiseValue1 = (hillNoise.get_noise_2d(currCoords.x, currCoords.z) + 1) / 2 - clamp((currCoords.y) * 0.01, 0, 1);
    
    hillval1 = val1 + (imageLoad(TEXTURES[100], texel1).r + 1) / 2 - (gl_GlobalInvocationID.z * information_buffer.hillScale) + information_buffer.hillOffset;
    hillval2 = val2 + (imageLoad(TEXTURES[100], texel2).r + 1) / 2 - (gl_GlobalInvocationID.z * information_buffer.hillScale) + information_buffer.hillOffset;
    hillval3 = val3 + (imageLoad(TEXTURES[100], texel3).r + 1) / 2 - (gl_GlobalInvocationID.z * information_buffer.hillScale) + information_buffer.hillOffset;
    hillval4 = val4 + (imageLoad(TEXTURES[100], texel4).r + 1) / 2 - (gl_GlobalInvocationID.z * information_buffer.hillScale) + information_buffer.hillOffset;
    hillval5 = val5 + (imageLoad(TEXTURES[100], texel5).r + 1) / 2 - (gl_GlobalInvocationID.z * information_buffer.hillScale) + information_buffer.hillOffset;
    hillval6 = val6 + (imageLoad(TEXTURES[100], texel1).r + 1) / 2 - ((gl_GlobalInvocationID.z + 1) * information_buffer.hillScale) + information_buffer.hillOffset;
    hillval7 = val7 + (imageLoad(TEXTURES[100], texel1).r + 1) / 2 - ((gl_GlobalInvocationID.z - 1) * information_buffer.hillScale) + information_buffer.hillOffset;

    //var mountainNoiseValue1 = (mountainNoise.get_noise_3dv(currCoords) + 1) / 2 + ((clipNoise.get_noise_2d(currCoords.x, currCoords.z) + 1) / 2 - clamp((currCoords.y) * 0.01, 0, 1));

    mountainval1 = val1 + (imageLoad(TEXTURES[101 + gl_GlobalInvocationID.z + 1], texel1).r - 1) + ((imageLoad(TEXTURES[203], texel1).r + 1) / 2 - (gl_GlobalInvocationID.z * information_buffer.clipScale) + information_buffer.clipOffset);
    mountainval2 = val2 + (imageLoad(TEXTURES[101 + gl_GlobalInvocationID.z + 1], texel2).r - 1) + ((imageLoad(TEXTURES[203], texel2).r + 1) / 2 - (gl_GlobalInvocationID.z * information_buffer.clipScale) + information_buffer.clipOffset);
    mountainval3 = val3 + (imageLoad(TEXTURES[101 + gl_GlobalInvocationID.z + 1], texel3).r - 1) + ((imageLoad(TEXTURES[203], texel3).r + 1) / 2 - (gl_GlobalInvocationID.z * information_buffer.clipScale) + information_buffer.clipOffset);
    mountainval4 = val4 + (imageLoad(TEXTURES[101 + gl_GlobalInvocationID.z + 1], texel4).r - 1) + ((imageLoad(TEXTURES[203], texel4).r + 1) / 2 - (gl_GlobalInvocationID.z * information_buffer.clipScale) + information_buffer.clipOffset);
    mountainval5 = val5 + (imageLoad(TEXTURES[101 + gl_GlobalInvocationID.z + 1], texel5).r - 1) + ((imageLoad(TEXTURES[203], texel5).r + 1) / 2 - (gl_GlobalInvocationID.z * information_buffer.clipScale) + information_buffer.clipOffset);
    mountainval6 = val6 + (imageLoad(TEXTURES[101 + gl_GlobalInvocationID.z + 2], texel1).r - 1) + ((imageLoad(TEXTURES[203], texel1).r + 1) / 2 - ((gl_GlobalInvocationID.z + 1) * information_buffer.clipScale) + information_buffer.clipOffset);
    mountainval7 = val7 + (imageLoad(TEXTURES[101 + gl_GlobalInvocationID.z], texel1).r - 1) + ((imageLoad(TEXTURES[203], texel1).r + 1) / 2 - ((gl_GlobalInvocationID.z - 1) * information_buffer.clipScale) + information_buffer.clipOffset);

    // val1 = hillval1;
    // val2 = hillval2;
    // val3 = hillval3;
    // val4 = hillval4;
    // val5 = hillval5;
    // val6 = hillval6;
    // val7 = hillval7;

    // val1 = mountainval1;
    // val2 = mountainval2;
    // val3 = mountainval3;
    // val4 = mountainval4;
    // val5 = mountainval5;
    // val6 = mountainval6;
    // val7 = mountainval7;

    val1 = clamp((hillval1 + mountainval1) / 2, 0, 1);
    val2 = clamp((hillval2 + mountainval2) / 2, 0, 1);
    val3 = clamp((hillval3 + mountainval3) / 2, 0, 1);
    val4 = clamp((hillval4 + mountainval4) / 2, 0, 1);
    val5 = clamp((hillval5 + mountainval5) / 2, 0, 1);
    val6 = clamp((hillval6 + mountainval6) / 2, 0, 1);
    val7 = clamp((hillval7 + mountainval7) / 2, 0, 1);
    

    // val1 = clamp((hillval1 - (1 - mountainval1) / 2), 0, 1);
    // val2 = clamp((hillval2 - (1 - mountainval2) / 2), 0, 1);
    // val3 = clamp((hillval3 - (1 - mountainval3) / 2), 0, 1);
    // val4 = clamp((hillval4 - (1 - mountainval4) / 2), 0, 1);
    // val5 = clamp((hillval5 - (1 - mountainval5) / 2), 0, 1);
    // val6 = clamp((hillval6 - (1 - mountainval6) / 2), 0, 1);
    // val7 = clamp((hillval7 - (1 - mountainval7) / 2), 0, 1);

    // val1 = clamp((mountainval1 - (1 - hillval1) / 2), 0, 1);
    // val2 = clamp((mountainval2 - (1 - hillval2) / 2), 0, 1);
    // val3 = clamp((mountainval3 - (1 - hillval3) / 2), 0, 1);
    // val4 = clamp((mountainval4 - (1 - hillval4) / 2), 0, 1);
    // val5 = clamp((mountainval5 - (1 - hillval5) / 2), 0, 1);
    // val6 = clamp((mountainval6 - (1 - hillval6) / 2), 0, 1);
    // val7 = clamp((mountainval7 - (1 - hillval7) / 2), 0, 1);


    //border
    int surface1 = int(val1 > information_buffer.airTreshold) - int(val2 > information_buffer.airTreshold);
    int surface2 = int(val1 > information_buffer.airTreshold) - int(val3 > information_buffer.airTreshold);
    int surface3 = int(val1 > information_buffer.airTreshold) - int(val6 > information_buffer.airTreshold);
    int surface4 = int(val1 > information_buffer.airTreshold) - int(val4 > information_buffer.airTreshold);
    int surface5 = int(val1 > information_buffer.airTreshold) - int(val5 > information_buffer.airTreshold);
    int surface6 = int(val1 > information_buffer.airTreshold) - int(val7 > information_buffer.airTreshold);
    if (surface1 > 0) {
        color += vec4(8.0 / 255.0, 0.0, 0.0, 0.0);
    }
    if (surface4 > 0) {
        color += vec4(1.0 / 255.0, 0.0, 0.0, 0.0);
    }
    if (surface2 > 0) {
        color += vec4(32.0 / 255.0, 0.0, 0.0, 0.0);
    }
    if (surface5 > 0) {
        color += vec4(4.0 / 255.0, 0.0, 0.0, 0.0);
    }
    if (surface3 > 0) {
        color += vec4(16.0 / 255.0, 0.0, 0.0, 0.0);
    }
    if (surface6 > 0) {
        color += vec4(2.0 / 255.0, 0.0, 0.0, 0.0);
    }
    imageStore(TEXTURES[gl_GlobalInvocationID.z], texel1, color);
}
