extends Node

# Called when the node enters the scene tree for the first time.
func _build(hill_Noise:Image, mountain_Noise:Array[Image], clip_Noise:Image, hill_scale:float, clip_scale:float, hill_offset:float, clip_offset:float, total_y_Size:int):
	var output_image_array:Array = [];
	
	var rd := RenderingServer.create_local_rendering_device();
	
	var shader_file := load("res://Script/WorldGenerator.glsl");
	var shader_spirv: RDShaderSPIRV = shader_file.get_spirv();
	var shader := rd.shader_create_from_spirv(shader_spirv);
	
	for l in 1:
		hill_Noise.convert(Image.FORMAT_RGBA8);
		clip_Noise.convert(Image.FORMAT_RGBA8);
		
		var fmt := RDTextureFormat.new();
		fmt.width = hill_Noise.get_width();
		fmt.height = hill_Noise.get_height();
		fmt.format = RenderingDevice.DATA_FORMAT_A8B8G8R8_UNORM_PACK32;
		fmt.usage_bits = RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT | RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT;
		
		var view := RDTextureView.new();
		var output_data_array:Array = [];
		var hill_input_tex = rd.texture_create(fmt, view, [hill_Noise.get_data()]);
		var clip_input_tex = rd.texture_create(fmt, view, [clip_Noise.get_data()]);
		var tex_uniform := RDUniform.new();
		tex_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE;
		tex_uniform.binding = 0;
		for i in total_y_Size:
			output_image_array.append(Image.create(hill_Noise.get_width(), hill_Noise.get_height(), false, Image.FORMAT_RGBA8));
			output_data_array.append(rd.texture_create(fmt, view, [output_image_array[i].get_data()]));
			tex_uniform.add_id(output_data_array[i]);
		tex_uniform.add_id(hill_input_tex);
		for i in total_y_Size + 2:
			mountain_Noise[i].convert(Image.FORMAT_RGBA8);
			tex_uniform.add_id(rd.texture_create(fmt, view, [mountain_Noise[i].get_data()]));
		tex_uniform.add_id(clip_input_tex);
		#var hill_input_tex_uniform := RDUniform.new();
		#hill_input_tex_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE;
		#hill_input_tex_uniform.binding = 0;
		#var mountain_input_tex_uniform := RDUniform.new();
		#mountain_input_tex_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE;
		#mountain_input_tex_uniform.binding = 0;
		var clip_input_tex_uniform := RDUniform.new();
		clip_input_tex_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE;
		clip_input_tex_uniform.binding = 1;
		var uniform_set := rd.uniform_set_create([tex_uniform], shader, 0);
		
		var information:PackedByteArray = PackedFloat32Array([total_y_Size, 0.25, hill_scale, clip_scale, hill_offset, clip_offset]).to_byte_array();
		var buffer := rd.storage_buffer_create(information.size(), information);
		var information_uniform := RDUniform.new();
		information_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER;
		information_uniform.binding = 0;
		information_uniform.add_id(buffer);
		var information_uniform_set := rd.uniform_set_create([information_uniform], shader, 1);
		
		var pipeline := rd.compute_pipeline_create(shader);
		var compute_list := rd.compute_list_begin();
		rd.compute_list_bind_compute_pipeline(compute_list, pipeline);
		rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0);
		rd.compute_list_bind_uniform_set(compute_list, information_uniform_set, 1);
		rd.compute_list_dispatch(compute_list, hill_Noise.get_width()/4, hill_Noise.get_height()/4, total_y_Size / 4);
		rd.compute_list_end();
		
		rd.submit();
		rd.sync();
		
		for i in total_y_Size:
			var byte_data1 : PackedByteArray = rd.texture_get_data(output_data_array[i], 0);
			var out_image := Image.create_from_data(hill_Noise.get_width(), hill_Noise.get_height(), false, Image.FORMAT_RGBA8, byte_data1);
			output_image_array[i] = out_image;
	
	return output_image_array;
