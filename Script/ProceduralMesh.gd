extends MeshInstance3D

@export var TotalWorldSize:Vector3i;
@export var WorldSize:Vector3i;
@export var ChunkSize:Vector3i;
@export var VoxelSize:float;
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
var collider;
var buildCollider:bool;

var meshes = [self]
var surfaceCount:int;
var colliderFacesDictionary:Dictionary = {};

var player;
var CollisionShape;
var currentPlayerPos:Vector3;
var previousPlayerPos;

var t:Vector3;
var w:Vector3;
var offset:Vector3;

func _ready():
	player = get_tree().root.get_node("Main").get_node("Entities").get_node("CharacterBody3D");
	CollisionShape = get_parent().get_child(0);
	
	for i in 5:
		Threads.append(Thread.new());
	
	collider = ConcavePolygonShape3D.new();
	CollisionShape.shape = collider;
	
	_build_world_texture();
	
	t = Vector3(TotalWorldSize.x, 0, TotalWorldSize.z);
	w = Vector3(WorldSize.x, 0, WorldSize.z);
	offset = Vector3(float(floor(t.x / 2) == t.x / 2), 0, float(floor(t.z / 2) == t.z / 2));

func _build_world_texture():
	finalNoiseTexture = [];
	
	for y in TotalWorldSize.y * ChunkSize.y:
		finalNoiseTexture.append(Image.create(TotalWorldSize.x * ChunkSize.x + 1, TotalWorldSize.z * ChunkSize.z + 1, false, Image.FORMAT_L8));
		finalNoiseTexture[y].fill(Color8(0, 0, 0, 0));
		for x in TotalWorldSize.x * ChunkSize.x:
			for z in TotalWorldSize.z * ChunkSize.z:
				var normalsList = [Vector3(1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, 1), Vector3(-1, 0, 0), Vector3(0, -1, 0), Vector3(0, 0, -1)]
				
				var voxelPos = Vector3(x - float(ChunkSize.x - 1) / 2, y, z - float(ChunkSize.z - 1) / 2) * VoxelSize - Vector3.ONE;
				
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
					if surface > 0:
						var prevValue = finalNoiseTexture[y].get_pixel(x, z);
						if face.x < 0:
							finalNoiseTexture[y].set_pixel(x, z, prevValue + Color8(1, 1, 1, 0));
						elif face.y < 0:
							finalNoiseTexture[y].set_pixel(x, z, prevValue + Color8(2, 2, 2, 0));
						elif face.z < 0:
							finalNoiseTexture[y].set_pixel(x, z, prevValue + Color8(4, 4, 4, 0));
						elif face.x > 0:
							finalNoiseTexture[y].set_pixel(x, z, prevValue + Color8(8, 8, 8, 0));
						elif face.y > 0:
							finalNoiseTexture[y].set_pixel(x, z, prevValue + Color8(16, 16, 16, 0));
						elif face.z > 0:
							finalNoiseTexture[y].set_pixel(x, z, prevValue + Color8(32, 32, 32, 0));

func _build_noise():
#	var mountainNoiseValue = (mountainNoise.get_noise_3d(_pos.x * ChunkSize + x - float(WorldSize.x * ChunkSize) / 2, _pos.y * ChunkSize + y, _pos.z * ChunkSize + z - float(WorldSize.z * ChunkSize) / 2) + 1) / 2 + ((clipNoise.get_noise_2d(_pos.x * ChunkSize + x - float(WorldSize.x * ChunkSize) / 2, _pos.z * ChunkSize + z - (WorldSize.z * ChunkSize) / 2) + 1) / 2 - clamp((_pos.y * ChunkSize + y) * 0.01, 0, 1));
#	var hillNoiseValue = (hillNoise.get_noise_2d(_pos.x * ChunkSize + x - float(WorldSize.x * ChunkSize) / 2, _pos.z * ChunkSize + z - float(WorldSize.z * ChunkSize) / 2) + 1) / 2 - clamp((_pos.y * ChunkSize + y) * 0.01, 0, 1);
#	var mountainTerrainValue = (mountainTerrainNoise.get_noise_2d(_pos.x * ChunkSize + x - float(ChunkSize) / 2, _pos.z * ChunkSize + z - float(ChunkSize) / 2) + 1) / 2 - clamp((_pos.y * ChunkSize + y) * 0.01, 0, 1);
#	var hillTerrainValue = (hillTerrainNoise.get_noise_2d(_pos.x * ChunkSize + x - float(ChunkSize) / 2, _pos.z * ChunkSize + z - float(ChunkSize) / 2) + 1) / 2 - clamp((_pos.y * ChunkSize + y) * 0.01, 0, 1);
#	var terrainValue = mountainNoiseValue1 * mountainTerrainValue1 + hillNoiseValue1 * hillTerrainValue1;
#	var surface = int(mountainNoiseValue1 > treshHold) - int(mountainNoiseValue2 > treshHold);
#	var surface = int(hillNoiseValue1 + 0.5 > treshHold) - int(hillNoiseValue2 + 0.5 > treshHold);
#	var surface = int((hillNoiseValue1 + 0.5 + mountainNoiseValue1) > treshHold) - int((hillNoiseValue2 + 0.5 + mountainNoiseValue2) > treshHold);
#	var surface = int(terrainValue1 + 0.5 > treshHold) - int(terrainValue2 + 0.5 > treshHold);
	
	var hillNoiseImage = hillNoise.get_image(TotalWorldSize.x * ChunkSize.x + 2, TotalWorldSize.z * ChunkSize.z + 2);
	print(hillNoiseImage)
	var hillNoiseValue = [];
	hillNoiseValue.resize(TotalWorldSize.y * ChunkSize.y + 2);

	for i in len(hillNoiseValue):
		var multiplier = 0.03;
		var heightOffset = 2.25;
		hillNoiseValue[i] = hillNoiseImage.duplicate(false);
		for x in hillNoiseValue[i].get_width():
			for z in hillNoiseValue[i].get_height():
				hillNoiseValue[i].set_pixel(x, z, hillNoiseValue[i].get_pixel(x, z) + Color.WHITE * (heightOffset - clamp(float(i) * multiplier, 0, 5)));
	
#	var mountainNoiseImage = mountainNoise.get_image_3d(TotalWorldSize.x * ChunkSize + 1, TotalWorldSize.z * ChunkSize + 1, TotalWorldSize.y * ChunkSize + 2);
#	var clipNoiseImage = clipNoise.get_image(TotalWorldSize.x * ChunkSize + 1, TotalWorldSize.z * ChunkSize + 1);
#	var mountainNoiseValue = [];
#	mountainNoiseValue.resize(TotalWorldSize.y * ChunkSize + 2);
#
#	for i in len(mountainNoiseValue):
#		var multiplier = 100;
#		var offset = 0;
#		mountainNoiseValue[i] = mountainNoiseImage[i].duplicate(false);
#		for x in mountainNoiseValue[i].get_width():
#			for z in mountainNoiseValue[i].get_height():
#				mountainNoiseValue[i].set_pixel(x, z, mountainNoiseValue[i].get_pixel(x, z) + (clipNoiseImage.get_pixel(x, z) - Color.WHITE * clamp(multiplier * float(i) / float(len(mountainNoiseValue)) * 0.01, 0, 5) + Color.WHITE * offset));
	
	finalNoiseTexture = hillNoiseValue;

func _cube_marching_thread(_pos, _noisePos, i):
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
						var n = localNormals[lv];
						if v not in verts:
							verts.append(v);
							normals.append(n)
							localIndecies.append(len(verts) - 1);
						else:
							var prevNormalValue = normals[verts.find(v)];
							var vertPower = max(max(abs(prevNormalValue.x), abs(prevNormalValue.y)), abs(prevNormalValue.z));
							var normalValue = (prevNormalValue / vertPower * (Vector3(1, 1, 1) - n) + n);
							normals[verts.find(v)] = normalValue / normalValue.length();
							localIndecies.append(verts.find(v));
					
					for l in len(localIndecies)/4:
						tris.append_array([localIndecies[4 * l], localIndecies[4 * l + 2], localIndecies[4 * l + 3], localIndecies[4 * l], localIndecies[4 * l + 3], localIndecies[4 * l + 1]]);
	if len(verts):
		verts.append((_pos - Vector3(TotalWorldSize.x - 1, 0, TotalWorldSize.z - 1) / 2) * Vector3(ChunkSize));
		normals.append(Vector3.UP);
	
	meshInfo.append({"verts": verts, "tris": tris, "normals": normals});
	call_deferred("_remove_thread", i);

func _build_mesh_thread(verts, tris, normals, i):
	var surface_array = [];
	if len(verts):
		surface_array.resize(Mesh.ARRAY_MAX);
#
		surface_array[Mesh.ARRAY_VERTEX] = verts;
#		surface_array[Mesh.ARRAY_TEX_UV] = uvs;
		surface_array[Mesh.ARRAY_NORMAL] = normals;
		surface_array[Mesh.ARRAY_INDEX] = tris;
		call("_add_surface_from_arrays", surface_array);
		call("_add_collider", verts, tris);
	call_deferred("_remove_thread", i);

func _remove_surface_thread(surfaces, bufferList, i):
	var s = 0;
	while s < len(surfaces):
		var _pos = (round(surfaces[s].aabb.position / Vector3(ChunkSize)) + Vector3(TotalWorldSize.x, 0, TotalWorldSize.z) / 2)
		if _pos not in bufferList:
#			var initIndex = int(colliderFacesDictionary[(round(surfaces[s].aabb.position / ChunkSize) + Vector3(TotalWorldSize.x, 0, TotalWorldSize.z) / 2)][0]);
#			var length = int(colliderFacesDictionary[(round(surfaces[s].aabb.position / ChunkSize) + Vector3(TotalWorldSize.x, 0, TotalWorldSize.z) / 2)][1]);
			surfaces.remove_at(s);
			surfaceCount -= 1;
			colliderFacesDictionary[_pos].queue_free();
			colliderFacesDictionary.erase(_pos);
#			for j in length:
#				colliderFaces.remove_at(initIndex);
#			for k in colliderFacesDictionary.values():
#				if k[0] > initIndex:
#					k[0] -= length;
		else:
			s += 1;
	mesh._set_surfaces(surfaces);
	call_deferred("_remove_thread", i);

func _add_surface_from_arrays(a):
	surfaceCount += 1;
	if surfaceCount % 200 == 0:
		var newMesh;
		newMesh = MeshInstance3D.new();
		newMesh.mesh = ArrayMesh.new();
		meshes.append(newMesh);
		newMesh.material_override = material_override;
		call_deferred("add_sibling", newMesh);
	meshes[len(meshes) - 1].mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, a);

func _add_collider(verts, tris):
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
	pass

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
							chunkInfo.append([chunkPos, checkPos]);
							builtChunks.append(chunkPos);
						currChunks.append(chunkPos);
		previousPlayerPos = currentPlayerPos;
		
		var c = 0
		while c < len(builtChunks):
			if builtChunks[c] not in currChunks:
				builtChunks.remove_at(c);
			else:
				c += 1;

		for i in len(Threads):
			if !Threads[i].is_started():
				var surfaces = [];
				for m in meshes:
					surfaces.append_array(m.mesh._get_surfaces())
				Threads[i].start(_remove_surface_thread.bind(surfaces, builtChunks.duplicate(false), Threads[i]));
				break;
	
	if len(meshInfo):
		for i in len(Threads):
			if !len(meshInfo):
				break;
			if !Threads[i].is_started():
				Threads[i].start(_build_mesh_thread.bind(meshInfo[0].verts, meshInfo[0].tris, meshInfo[0].normals, Threads[i]));
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
				Threads[i].start(_cube_marching_thread.bind(chunkInfo[0][0], chunkInfo[0][1], Threads[i]));
				chunkInfo.remove_at(0);

