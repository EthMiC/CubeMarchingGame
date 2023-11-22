extends Node

# Called when the node enters the scene tree for the first time.
func _build(hill_Noise:Array[Image], hill_scale:float, clip_scale:float):
	var output_image_array:Array = [];
	for i in len(hill_Noise):
		output_image_array.append(Image.create(hill_Noise[0].get_width(), hill_Noise[0].get_height(), false, Image.FORMAT_RGBA8));
	
	var rd := RenderingServer.create_local_rendering_device();
	
	var shader_file := load("res://Script/WorldGenerator.glsl");
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv();
	var shader := rd.shader_create_from_spirv(shader_spirv);
	
	for i in len(hill_Noise) - 1:
		var image0 = hill_Noise[i - 1] if i > 0 else Image.create(hill_Noise[0].get_width(), hill_Noise[0].get_height(), false, Image.FORMAT_RGBA8);
		var image1 = hill_Noise[i];
		var image2 = hill_Noise[i + 1];
		
		var output_image = output_image_array[i];
		
		var fmt := RDTextureFormat.new();
		fmt.width = image1.get_width();
		fmt.height = image1.get_height();
		fmt.format = RenderingDevice.DATA_FORMAT_A8B8G8R8_UNORM_PACK32;
		fmt.usage_bits = RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT | RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT;
		
		var view := RDTextureView.new();
		image1.convert(Image.FORMAT_RGBA8);
		image2.convert(Image.FORMAT_RGBA8);
		var output_tex = rd.texture_create(fmt, view, [output_image.get_data()]);
		var output_tex_uniform := RDUniform.new();
		output_tex_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE;
		output_tex_uniform.binding = 0;
		output_tex_uniform.add_id(output_tex);
		var input_tex0 = rd.texture_create(fmt, view, [image0.get_data()]);
		var input_tex_uniform0 := RDUniform.new();
		input_tex_uniform0.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE;
		input_tex_uniform0.binding = 1;
		input_tex_uniform0.add_id(input_tex0);
		var input_tex1 = rd.texture_create(fmt, view, [image1.get_data()]);
		var input_tex_uniform1 := RDUniform.new();
		input_tex_uniform1.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE;
		input_tex_uniform1.binding = 2;
		input_tex_uniform1.add_id(input_tex1);
		var input_tex2 = rd.texture_create(fmt, view, [image2.get_data()]);
		var input_tex_uniform2 := RDUniform.new();
		input_tex_uniform2.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE;
		input_tex_uniform2.binding = 3;
		input_tex_uniform2.add_id(input_tex2);
		var tex_uniform_set := rd.uniform_set_create([output_tex_uniform, input_tex_uniform0, input_tex_uniform1, input_tex_uniform2], shader, 0);
		
		var information:PackedByteArray = PackedFloat32Array([i, hill_scale, clip_scale]).to_byte_array();
		var buffer := rd.storage_buffer_create(information.size(), information);
		var information_uniform := RDUniform.new();
		information_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER;
		information_uniform.binding = 0;
		information_uniform.add_id(buffer);
		var information_uniform_set := rd.uniform_set_create([information_uniform], shader, 1);
		
		var pipeline := rd.compute_pipeline_create(shader);
		var compute_list := rd.compute_list_begin();
		rd.compute_list_bind_compute_pipeline(compute_list, pipeline);
		rd.compute_list_bind_uniform_set(compute_list, tex_uniform_set, 0);
		rd.compute_list_bind_uniform_set(compute_list, information_uniform_set, 1);
		rd.compute_list_dispatch(compute_list, image1.get_width()/8, image1.get_height()/8, 1);
		rd.compute_list_end();
		
		rd.submit();
		rd.sync();
#
		var byte_data1 : PackedByteArray = rd.texture_get_data(output_tex, 0);
		var out_image := Image.create_from_data(image1.get_width(), image1.get_height(), false, Image.FORMAT_RGBA8, byte_data1);

		output_image_array[i] = out_image;
	return output_image_array;
