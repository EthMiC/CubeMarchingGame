#[compute]
#version 450

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(set = 0, binding = 0, rgba8) uniform image2D OUTPUT_TEXTURE;

layout(set = 0, binding = 1, rgba8) uniform image2D INPUT_TEXTURE0;
layout(set = 0, binding = 2, rgba8) uniform image2D INPUT_TEXTURE1;
layout(set = 0, binding = 3, rgba8) uniform image2D INPUT_TEXTURE2;

layout(set = 1, binding = 0) restrict buffer InformationBuffer {
    float y_val;
    float hillScale;
    float clipScale;
}
information_buffer;

void main() {
    //information
    vec4 color;
    ivec2 texel1 = ivec2(gl_GlobalInvocationID.xy);
    ivec2 texel2 = ivec2(gl_GlobalInvocationID.xy + vec2(1, 0));
    ivec2 texel3 = ivec2(gl_GlobalInvocationID.xy + vec2(0, 1));
    ivec2 texel4 = ivec2(gl_GlobalInvocationID.xy - vec2(1, 0));
    ivec2 texel5 = ivec2(gl_GlobalInvocationID.xy - vec2(0, 1));

    //update buffer textures
	//var hillNoiseValue1 = (hillNoise.get_noise_2d(currCoords.x, currCoords.z) + 1) / 2 - clamp((currCoords.y) * 0.01, 0, 1);
    float val1 = (imageLoad(INPUT_TEXTURE1, texel1).r + 1) / 2 - clamp(information_buffer.y_val * information_buffer.hillScale, 0, 1);
    float val2 = (imageLoad(INPUT_TEXTURE1, texel2).r + 1) / 2 - clamp(information_buffer.y_val * information_buffer.hillScale, 0, 1);
    float val3 = (imageLoad(INPUT_TEXTURE1, texel3).r + 1) / 2 - clamp(information_buffer.y_val * information_buffer.hillScale, 0, 1);
    float val4 = (imageLoad(INPUT_TEXTURE1, texel4).r + 1) / 2 - clamp(information_buffer.y_val * information_buffer.hillScale, 0, 1);
    float val5 = (imageLoad(INPUT_TEXTURE1, texel5).r + 1) / 2 - clamp(information_buffer.y_val * information_buffer.hillScale, 0, 1);
    float val6 = (imageLoad(INPUT_TEXTURE2, texel1).r + 1) / 2 - clamp((information_buffer.y_val + 1) * information_buffer.hillScale, 0, 1);
    float val7 = (imageLoad(INPUT_TEXTURE0, texel1).r + 1) / 2 - clamp((information_buffer.y_val - 1) * information_buffer.hillScale, 0, 1);


    //border
    // float val1 = imageLoad(INPUT_TEXTURE1, texel1).r;
    // float val2 = imageLoad(INPUT_TEXTURE1, texel2).r;
    // float val3 = imageLoad(INPUT_TEXTURE1, texel3).r;
    // float val4 = imageLoad(INPUT_TEXTURE1, texel4).r;
    // float val5 = imageLoad(INPUT_TEXTURE1, texel5).r;
    // float val6 = imageLoad(INPUT_TEXTURE2, texel1).r;
    // float val7 = imageLoad(INPUT_TEXTURE0, texel1).r;
    int surface1 = int(val1 > 0.5) - int(val2 > 0.5);
    int surface2 = int(val1 > 0.5) - int(val3 > 0.5);
    int surface3 = int(val1 > 0.5) - int(val6 > 0.5);
    int surface4 = int(val1 > 0.5) - int(val4 > 0.5);
    int surface5 = int(val1 > 0.5) - int(val5 > 0.5);
    int surface6 = int(val1 > 0.5) - int(val7 > 0.5);
    if (surface1 > 0) {
        color = vec4(8.0 / 256.0, 0.0, 0.0, 1.0);
        imageStore(OUTPUT_TEXTURE, texel1, imageLoad(OUTPUT_TEXTURE, texel1) + color);
    }
    if (surface4 > 0) {
        color = vec4(1.0 / 256.0, 0.0, 0.0, 1.0);
        imageStore(OUTPUT_TEXTURE, texel1, imageLoad(OUTPUT_TEXTURE, texel1) + color);
    }
    if (surface2 > 0) {
        color = vec4(32.0 / 256.0, 0.0, 0.0, 1.0);
        imageStore(OUTPUT_TEXTURE, texel1, imageLoad(OUTPUT_TEXTURE, texel1) + color);
    }
    if (surface5 > 0) {
        color = vec4(4.0 / 256.0, 0.0, 0.0, 1.0);
        imageStore(OUTPUT_TEXTURE, texel1, imageLoad(OUTPUT_TEXTURE, texel1) + color);
    }
    if (surface3 > 0) {
        color = vec4(16.0 / 256.0, 0.0, 0.0, 1.0);
        imageStore(OUTPUT_TEXTURE, texel1, imageLoad(OUTPUT_TEXTURE, texel1) + color);
    }
    if (surface6 > 0) {
        color = vec4(2.0 / 256.0, 0.0, 0.0, 1.0);
        imageStore(OUTPUT_TEXTURE, texel1, imageLoad(OUTPUT_TEXTURE, texel1) + color);
    }
}
