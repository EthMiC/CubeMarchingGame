extends MeshInstance3D

@export var TotalWorldSize:Vector3i;
@export var WorldSize:Vector3i;
@export var ChunkSize:Vector3i;
@export var treshHold = 0.25;

@export var mountainNoise:FastNoiseLite;
@export var hillNoise:FastNoiseLite;
@export var mountainTerrainNoise:FastNoiseLite;
@export var hillTerrainNoise:FastNoiseLite;
@export var clipNoise:FastNoiseLite;

var finalNoiseTexture;

var Threads = [];
var chunkInfo = [];
var meshInfo = [];
var builtChunks = [];
var currChunks = [];
var buildCollider:bool;

var meshes = [self]
var surfaceCount:int;
var surfacePerMesh:int = 200;
var colliderFacesDictionary:Dictionary = {};

var player;
var currentPlayerPos:Vector3;
var previousPlayerPos;

var t:Vector3;
var w:Vector3;
var offset:Vector3;

var buildFile = preload("res://Script/WorldTextureGenerator.gd");

func _ready():
	player = get_tree().root.get_node("Main").get_node("Entities").get_node("CharacterBody3D");
	
	for i in 5:
		Threads.append(Thread.new());
	
	_build_world_texture_gpu();
	
	t = Vector3(TotalWorldSize.x, 0, TotalWorldSize.z);
	w = Vector3(WorldSize.x, 0, WorldSize.z);
	offset = Vector3(float(floor(t.x / 2) == t.x / 2), 0, float(floor(t.z / 2) == t.z / 2));

func _build_world_texture_gpu():
	var hillNoiseImage = hillNoise.get_image(TotalWorldSize.x * ChunkSize.x + 2, TotalWorldSize.z * ChunkSize.z + 2, TotalWorldSize.y * ChunkSize.y + 2);
	var mountainNoiseImage = mountainNoise.get_image_3d(TotalWorldSize.x * ChunkSize.x + 2, TotalWorldSize.z * ChunkSize.z + 2, TotalWorldSize.y * ChunkSize.y + 2);
	var clipNoiseImage = clipNoise.get_image(TotalWorldSize.x * ChunkSize.x + 2, TotalWorldSize.z * ChunkSize.z + 2);
	finalNoiseTexture = buildFile.new()._build(hillNoiseImage, mountainNoiseImage, clipNoiseImage, 0.005, 0.0125, 0, 0.5, ChunkSize.y * TotalWorldSize.y);

func _build_world_texture():
	finalNoiseTexture = [];
	
	for y in TotalWorldSize.y * ChunkSize.y:
		finalNoiseTexture.append(Image.create(TotalWorldSize.x * ChunkSize.x + 1, TotalWorldSize.z * ChunkSize.z + 1, false, Image.FORMAT_L8));
		finalNoiseTexture[y].fill(Color8(0, 0, 0, 0));
		for x in TotalWorldSize.x * ChunkSize.x:
			for z in TotalWorldSize.z * ChunkSize.z:
				var normalsList = [Vector3(1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, 1)]
				
				var voxelPos = Vector3(x - float(ChunkSize.x - 1) / 2, y, z - float(ChunkSize.z - 1) / 2) - Vector3.ONE;
				
				for face in normalsList:
					var currCoords = Vector3(x, y, z);
					var nextCoords = currCoords + face;
					var mountainNoiseValue1 = (mountainNoise.get_noise_3dv(currCoords) + 1) / 2 + ((clipNoise.get_noise_2d(currCoords.x, currCoords.z) + 1) / 2 - clamp((currCoords.y) * 0.01, 0, 1));
					var mountainNoiseValue2 = (mountainNoise.get_noise_3dv(nextCoords) + 1) / 2 + ((clipNoise.get_noise_2d(nextCoords.x, nextCoords.z) + 1) / 2 - clamp((nextCoords.y) * 0.01, 0, 1));
					var hillNoiseValue1 = (hillNoise.get_noise_2d(currCoords.x, currCoords.z) + 1) / 2 - clamp((currCoords.y) * 0.01, 0, 1);
					var hillNoiseValue2 = (hillNoise.get_noise_2d(nextCoords.x, nextCoords.z) + 1) / 2 - clamp((nextCoords.y) * 0.01, 0, 1);
#					var mountainTerrainValue1 = (mountainTerrainNoise.get_noise_2d(_pos.x * ChunkSize + x - float(ChunkSize) / 2, _pos.z * ChunkSize + z - float(ChunkSize) / 2) + 1) / 2 - clamp((_pos.y * ChunkSize + y) * 0.01, 0, 1);
#					var mountainTerrainValue2 = (mountainTerrainNoise.get_noise_2d(_pos.x * ChunkSize + x + face.x - float(ChunkSize) / 2, _pos.z * ChunkSize + z + face.z - float(ChunkSize) / 2) + 1) / 2 - clamp((_pos.y * ChunkSize + y + face.y) * 0.01, 0, 1);
#					var hillTerrainValue1 = (hillTerrainNoise.get_noise_2d(_pos.x * ChunkSize + x - float(ChunkSize) / 2, _pos.z * ChunkSize + z - float(ChunkSize) / 2) + 1) / 2 - clamp((_pos.y * ChunkSize + y) * 0.01, 0, 1);
#					var hillTerrainValue2 = (hillTerrainNoise.get_noise_2d(_pos.x * ChunkSize + x + face.x - float(ChunkSize) / 2, _pos.z * ChunkSize + z + face.z - float(ChunkSize) / 2) + 1) / 2 - clamp((_pos.y * ChunkSize + y + face.y) * 0.01, 0, 1);
#					var terrainValue1 = mountainNoiseValue1 * mountainTerrainValue1 + hillNoiseValue1 * hillTerrainValue1;
#					var terrainValue2 = mountainNoiseValue2 * mountainTerrainValue2 + hillNoiseValue2 * hillTerrainValue2;
#					var surface = int(mountainNoiseValue1 > treshHold) - int(mountainNoiseValue2 > treshHold);
#					var surface = int(hillNoiseValue1 + 0.5 > treshHold) - int(hillNoiseValue2 + 0.5 > treshHold);
					var surface = int((hillNoiseValue1 + 0.5 + mountainNoiseValue1) > treshHold) - int((hillNoiseValue2 + 0.5 + mountainNoiseValue2) > treshHold);
#					var surface = int(terrainValue1 + 0.5 > treshHold) - int(terrainValue2 + 0.5 > treshHold);
					if surface < 0: 
						var prevValue = finalNoiseTexture[y + face.y].get_pixel(x + face.x, z + face.z);
						if face.x > 0:
							finalNoiseTexture[y].set_pixel(x + face.x, z, prevValue + Color8(1, 1, 1, 0));
						elif face.y > 0:
							finalNoiseTexture[y + face.y].set_pixel(x, z, prevValue + Color8(2, 2, 2, 0));
						elif face.z > 0:
							finalNoiseTexture[y].set_pixel(x, z + face.z, prevValue + Color8(4, 4, 4, 0));
					elif surface > 0:
						var prevValue = finalNoiseTexture[y].get_pixel(x, z);
						if face.x > 0:
							finalNoiseTexture[y].set_pixel(x, z, prevValue + Color8(8, 8, 8, 0));
						elif face.y > 0:
							finalNoiseTexture[y].set_pixel(x, z, prevValue + Color8(16, 16, 16, 0));
						elif face.z > 0:
							finalNoiseTexture[y].set_pixel(x, z, prevValue + Color8(32, 32, 32, 0));

func _cube_marching_thread(_pos, _noisePos, i, update:bool = false):
	var verts:PackedVector3Array = [];
	var tris:PackedInt32Array = []; 
	var normals:PackedVector3Array = [];
	for x in ChunkSize.x:
		for y in ChunkSize.y:
			for z in ChunkSize.z:
				var currCoords = Vector3(x, y, z) + _pos * Vector3(ChunkSize);
				var noiseCoords = Vector3(x, y, z) + _noisePos * Vector3(ChunkSize);
				var surface = round(finalNoiseTexture[noiseCoords.y].get_pixel(noiseCoords.x, noiseCoords.z).r * 2 ** 8);
				if surface:
					var localVertecies = [];
					var localNormals = [];
					var localIndecies = [];
					if surface >= 32:
						localVertecies.append_array([Vector3(-0.5, -0.5, 0.5), Vector3(0.5, -0.5, 0.5), Vector3(-0.5, 0.5, 0.5), Vector3(0.5, 0.5, 0.5)]);
						localNormals.append_array([Vector3(0, 0, 1), Vector3(0, 0, 1), Vector3(0, 0, 1), Vector3(0, 0, 1)]);
						surface -= 32;
					if surface >= 16:
						localVertecies.append_array([Vector3(-0.5, 0.5, -0.5), Vector3(-0.5, 0.5, 0.5), Vector3(0.5, 0.5, -0.5), Vector3(0.5, 0.5, 0.5)]);
						localNormals.append_array([Vector3(0, 1, 0), Vector3(0, 1, 0), Vector3(0, 1, 0), Vector3(0, 1, 0)]);
						surface -= 16;
					if surface >= 8:
						localVertecies.append_array([Vector3(0.5, -0.5, -0.5), Vector3(0.5, 0.5, -0.5), Vector3(0.5, -0.5, 0.5), Vector3(0.5, 0.5, 0.5)]);
						localNormals.append_array([Vector3(1, 0, 0), Vector3(1, 0, 0), Vector3(1, 0, 0), Vector3(1, 0, 0)]);
						surface -= 8;
					if surface >= 4:
						localVertecies.append_array([Vector3(-0.5, -0.5, -0.5), Vector3(-0.5, 0.5, -0.5), Vector3(0.5, -0.5, -0.5), Vector3(0.5, 0.5, -0.5)]);
						localNormals.append_array([Vector3(0, 0, -1), Vector3(0, 0, -1), Vector3(0, 0, -1), Vector3(0, 0, -1)]);
						surface -= 4;
					if surface >= 2:
						localVertecies.append_array([Vector3(-0.5, -0.5, -0.5), Vector3(0.5, -0.5, -0.5), Vector3(-0.5, -0.5, 0.5), Vector3(0.5, -0.5, 0.5)]);
						localNormals.append_array([Vector3(0, -1, 0), Vector3(0, -1, 0), Vector3(0, -1, 0), Vector3(0, -1, 0)]);
						surface -= 2;
					if surface >= 1:
						localVertecies.append_array([Vector3(-0.5, -0.5, -0.5), Vector3(-0.5, -0.5, 0.5), Vector3(-0.5, 0.5, -0.5), Vector3(-0.5, 0.5, 0.5)]);
						localNormals.append_array([Vector3(-1, 0, 0), Vector3(-1, 0, 0), Vector3(-1, 0, 0), Vector3(-1, 0, 0)]);
						surface -= 1;
					
					for lv in len(localVertecies):
						var v = currCoords + localVertecies[lv];
						if v not in verts:
							verts.append(v);
							localIndecies.append(len(verts) - 1);
						else:
							localIndecies.append(verts.find(v));
					
					for l in len(localIndecies)/4:
						tris.append_array([localIndecies[4 * l], localIndecies[4 * l + 2], localIndecies[4 * l + 3], localIndecies[4 * l], localIndecies[4 * l + 3], localIndecies[4 * l + 1]]);
	if len(verts) > 0:
		verts.append((_pos - Vector3(TotalWorldSize.x - 1, 0, TotalWorldSize.z - 1) / 2) * Vector3(ChunkSize));
		normals.append(Vector3.UP);
	
	meshInfo.append({"verts": verts, "tris": tris});
	
	if update:
		var surfaces = []
		for m in meshes:
			surfaces.append_array(m.mesh._get_surfaces());
		for l in len(Threads):
			if !Threads[l].is_started():
				Threads[l].start(_remove_surface_thread.bind(surfaces.duplicate(true), [round(verts[len(verts) - 1] / Vector3(ChunkSize)) + Vector3(TotalWorldSize.x, 0, TotalWorldSize.z) / 2], Threads[l], true));
				break;
	
	call_deferred("_remove_thread", i);

func _build_mesh_thread(verts, tris, i):
	var surface_array = [];
	if len(verts):
		surface_array.resize(Mesh.ARRAY_MAX);
#
		surface_array[Mesh.ARRAY_VERTEX] = verts;
#		surface_array[Mesh.ARRAY_TEX_UV] = uvs;
		#surface_array[Mesh.ARRAY_NORMAL] = normals;
		surface_array[Mesh.ARRAY_INDEX] = tris;
		call("_add_surface_from_arrays", surface_array);
		call("_add_collider", verts, tris);
	call_deferred("_remove_thread", i);

func _remove_surface_thread(surfaces, bufferList, i, specific):
	var s = 0;
	while s < len(surfaces):
		var _pos = (round(surfaces[s].aabb.position / Vector3(ChunkSize)) + Vector3(TotalWorldSize.x, 0, TotalWorldSize.z) / 2);
		if !specific:
			if _pos not in bufferList:
				surfaces.remove_at(s);
				surfaceCount -= 1;
				
				if colliderFacesDictionary.has(_pos):
					colliderFacesDictionary[_pos].queue_free();
					colliderFacesDictionary.erase(_pos);
			else:
				s += 1;
		else:
			if _pos in bufferList:
				bufferList.erase(_pos);
				surfaces.remove_at(s);
				surfaceCount -= 1;
			else:
				s += 1;
	for m in len(meshes):
		if surfacePerMesh * m <= len(surfaces):
			meshes[m].mesh._set_surfaces(surfaces.slice(surfacePerMesh * m, surfacePerMesh * (m + 1)));
		else:
			meshes[m].mesh._set_surfaces([]);
	call_deferred("_remove_thread", i);

func _add_surface_from_arrays(a):
	if surfaceCount / surfacePerMesh > len(meshes) - 1:
		var newMesh;
		newMesh = MeshInstance3D.new();
		newMesh.mesh = ArrayMesh.new();
		meshes.append(newMesh);
		newMesh.material_override = material_override;
		call_deferred("add_sibling", newMesh);
	var thisMesh = meshes[min(len(meshes) - 1, int(surfaceCount / surfacePerMesh))].mesh;
	thisMesh.call_deferred("add_surface_from_arrays", Mesh.PRIMITIVE_TRIANGLES, a, [], {}, 0);
	surfaceCount += 1;

func _add_collider(verts, tris):
	if !(colliderFacesDictionary.has((round(verts[len(verts) - 1] / Vector3(ChunkSize)) + Vector3(TotalWorldSize.x, 0, TotalWorldSize.z) / 2))):
		var newColliderShape = ConcavePolygonShape3D.new();
		var newCollider = CollisionShape3D.new();
		newCollider.shape = newColliderShape;
		var faces:PackedVector3Array = [];
		for j in tris:
			faces.append(verts[j]);
		colliderFacesDictionary[(round(verts[len(verts) - 1] / Vector3(ChunkSize)) + Vector3(TotalWorldSize.x, 0, TotalWorldSize.z) / 2)] = newCollider;
		newColliderShape.set_faces(faces);
	#	colliderFaces.append_array(faces);
		call_deferred("add_sibling", newCollider);
	else:
		var faces:PackedVector3Array = [];
		for j in tris:
			faces.append(verts[j]);
		colliderFacesDictionary[(round(verts[len(verts) - 1] / Vector3(ChunkSize)) + Vector3(TotalWorldSize.x, 0, TotalWorldSize.z) / 2)].shape.call_deferred("set_faces", faces);

func _commit_collider(i):
	call_deferred("_remove_thread", i);

func _remove_thread(th):
	th.wait_to_finish();

func _physics_process(_delta):
	currentPlayerPos = round(player.position / Vector3(ChunkSize)) * Vector3(1, 0, 1);
	currChunks = [];
	
	if currentPlayerPos != previousPlayerPos:
#		collider.set_faces(colliderFaces);
		for x in WorldSize.x:
			for y in WorldSize.y:
				for z in WorldSize.z:
					var checkPos = Vector3(x, y, z) + currentPlayerPos + floor((t - w) / 2);
					var chunkPos = Vector3(x, y, z) + currentPlayerPos - (t - 2 * floor((t - w) / 2)) / 2;
					if checkPos.x >= 0 && checkPos.x < TotalWorldSize.x && checkPos.y >= 0 && checkPos.y < TotalWorldSize.y && checkPos.z >= 0 && checkPos.z < TotalWorldSize.z:
						if chunkPos not in builtChunks:
							chunkInfo.append([chunkPos, checkPos, false]);
						currChunks.append(chunkPos);
		previousPlayerPos = currentPlayerPos;
		
		builtChunks = currChunks.duplicate(false);
		
		var surfaces = []
		for m in meshes:
			surfaces.append_array(m.mesh._get_surfaces());
		for i in len(Threads):
			if !Threads[i].is_started():
				Threads[i].start(_remove_surface_thread.bind(surfaces.duplicate(true), builtChunks.duplicate(false), Threads[i], false));
				break;
	
	if len(meshInfo):
		for i in len(Threads):
			if !len(meshInfo):
				break;
			if !Threads[i].is_started():
				Threads[i].start(_build_mesh_thread.bind(meshInfo[0].verts, meshInfo[0].tris, Threads[i]));
#				_build_mesh_thread(meshInfo[0].verts, meshInfo[0].tris, meshInfo[0].normals, Threads[i])
				meshInfo.remove_at(0);
#	if collider.get_faces() != colliderFaces:
#		var initTime = Time.get_ticks_usec();
#		collider.set_faces(colliderFaces);
#		var delta = Time.get_ticks_usec() - initTime;
#		print(delta);
	
	if len(chunkInfo):
		for i in len(Threads):
			if !len(chunkInfo):
				break;
			if !Threads[i].is_started():
				Threads[i].start(_cube_marching_thread.bind(chunkInfo[0][0], chunkInfo[0][1], Threads[i], chunkInfo[0][2]));
				chunkInfo.remove_at(0);

func updateChunk(blockPos:Vector3, add:bool):
	var pixelPos = blockPos + (t) * Vector3(ChunkSize.x, 1, ChunkSize.z) / 2;
	if pixelPos.x < 0 || pixelPos.x >= (TotalWorldSize.x * ChunkSize.x) - 1 || pixelPos.y < 0 || pixelPos.y >= (TotalWorldSize.y * ChunkSize.y) - 1 || pixelPos.z < 0 || pixelPos.z >= (TotalWorldSize.z * ChunkSize.z) - 1:
		return;
	if add:
		var val = 0;
		if finalNoiseTexture[pixelPos.y].get_pixel(pixelPos.x, pixelPos.z - 1).r * ((2 ** 8) - 1) >= 32:
			finalNoiseTexture[pixelPos.y].set_pixel(pixelPos.x, pixelPos.z - 1, Color8(int(finalNoiseTexture[pixelPos.y].get_pixel(pixelPos.x, pixelPos.z - 1).r * ((2 ** 8) - 1)) - 32, 0, 0, 0));
		else:
			val += 4;
		if finalNoiseTexture[pixelPos.y + 1].get_pixel(pixelPos.x, pixelPos.z).r * ((2 ** 8) - 1) >= 16:
			finalNoiseTexture[pixelPos.y + 1].set_pixel(pixelPos.x, pixelPos.z, Color8(int(finalNoiseTexture[pixelPos.y + 1].get_pixel(pixelPos.x, pixelPos.z).r * ((2 ** 8) - 1)) - 16, 0, 0, 0));
		else:
			val += 2;
		if finalNoiseTexture[pixelPos.y].get_pixel(pixelPos.x - 1, pixelPos.z).r * ((2 ** 8) - 1) >= 8:
			finalNoiseTexture[pixelPos.y].set_pixel(pixelPos.x - 1, pixelPos.z, Color8(int(finalNoiseTexture[pixelPos.y].get_pixel(pixelPos.x - 1, pixelPos.z).r * ((2 ** 8) - 1)) - 8, 0, 0, 0));
		else:
			val += 1;
		if finalNoiseTexture[pixelPos.y].get_pixel(pixelPos.x, pixelPos.z + 1).r * ((2 ** 8) - 1) >= 4:
			finalNoiseTexture[pixelPos.y].set_pixel(pixelPos.x, pixelPos.z + 1, Color8(int(finalNoiseTexture[pixelPos.y].get_pixel(pixelPos.x, pixelPos.z + 1).r * ((2 ** 8) - 1)) - 4, 0, 0, 0));
		else:
			val += 32;
		if finalNoiseTexture[pixelPos.y + 1].get_pixel(pixelPos.x, pixelPos.z).r * ((2 ** 8) - 1) >= 2:
			finalNoiseTexture[pixelPos.y + 1].set_pixel(pixelPos.x, pixelPos.z, Color8(int(finalNoiseTexture[pixelPos.y + 1].get_pixel(pixelPos.x, pixelPos.z).r * ((2 ** 8) - 1)) - 2, 0, 0, 0));
		else:
			val += 16;
		if finalNoiseTexture[pixelPos.y].get_pixel(pixelPos.x + 1, pixelPos.z).r * ((2 ** 8) - 1) >= 1:
			finalNoiseTexture[pixelPos.y].set_pixel(pixelPos.x + 1, pixelPos.z, Color8(int(finalNoiseTexture[pixelPos.y].get_pixel(pixelPos.x + 1, pixelPos.z).r * ((2 ** 8) - 1)) - 1, 0, 0, 0));
		else:
			val += 8;
		finalNoiseTexture[pixelPos.y].set_pixel(pixelPos.x, pixelPos.z, finalNoiseTexture[pixelPos.y].get_pixel(pixelPos.x, pixelPos.z) + Color8(val, 0, 0, 0));
	else:
		var surface = finalNoiseTexture[pixelPos.y].get_pixel(pixelPos.x, pixelPos.z).r * 2 ** 8;
		if surface >= 32:
			surface -= 32;
		else:
			finalNoiseTexture[pixelPos.y].set_pixel(pixelPos.x, pixelPos.z + 1, finalNoiseTexture[pixelPos.y].get_pixel(pixelPos.x, pixelPos.z + 1) + Color8(4, 0, 0, 0));
		if surface >= 16:
			surface -= 16;
		else:
			finalNoiseTexture[pixelPos.y + 1].set_pixel(pixelPos.x, pixelPos.z, finalNoiseTexture[pixelPos.y + 1].get_pixel(pixelPos.x, pixelPos.z) + Color8(2, 0, 0, 0));
		if surface >= 8:
			surface -= 8;
		else:
			finalNoiseTexture[pixelPos.y].set_pixel(pixelPos.x + 1, pixelPos.z, finalNoiseTexture[pixelPos.y].get_pixel(pixelPos.x + 1, pixelPos.z) + Color8(1, 0, 0, 0));
		if surface >= 4:
			surface -= 4;
		else:
			finalNoiseTexture[pixelPos.y].set_pixel(pixelPos.x, pixelPos.z - 1, finalNoiseTexture[pixelPos.y].get_pixel(pixelPos.x, pixelPos.z - 1) + Color8(32, 0, 0, 0));
		if surface >= 2:
			surface -= 2;
		else:
			finalNoiseTexture[pixelPos.y - 1].set_pixel(pixelPos.x, pixelPos.z, finalNoiseTexture[pixelPos.y - 1].get_pixel(pixelPos.x, pixelPos.z) + Color8(16, 0, 0, 0));
		if surface >= 1:
			surface -= 1;
		else:
			finalNoiseTexture[pixelPos.y].set_pixel(pixelPos.x - 1, pixelPos.z, finalNoiseTexture[pixelPos.y].get_pixel(pixelPos.x - 1, pixelPos.z) + Color8(8, 0, 0, 0));
		finalNoiseTexture[pixelPos.y].set_pixel(pixelPos.x, pixelPos.z, Color8(0, 0, 0));
	chunkInfo.append([floor((blockPos / Vector3(ChunkSize)) - ((Vector3(1, 0, 1) * t - (2 * floor(t/2))) / 2)) + ((Vector3(1, 0, 1) * t - (2 * floor(t/2))) / 2), floor(pixelPos / Vector3(ChunkSize)), true]);
	#var possibleBorders = [Vector3(1, 0, 0), Vector3(0, 0, 1), Vector3(-1, 0, 0), Vector3(0, 0, -1)];
	#for p in possibleBorders:
		#if floor(blockPos / Vector3(ChunkSize)) * Vector3(TotalWorldSize.x, 0, TotalWorldSize.z) / 2 != floor((blockPos + p) / Vector3(ChunkSize)) * Vector3(TotalWorldSize.x, 0, TotalWorldSize.z) / 2:
			#chunkInfo.append([floor(blockPos / Vector3(ChunkSize)) * Vector3(TotalWorldSize.x, 0, TotalWorldSize.z) / 2 + p, floor(pixelPos / Vector3(ChunkSize)) * Vector3(TotalWorldSize.x, 0, TotalWorldSize.z) / 2 + p, true]);

