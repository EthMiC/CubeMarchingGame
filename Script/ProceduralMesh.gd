extends MeshInstance3D

@export var WorldSize:Vector3i;
@export var ChunkSize:int;
@export var VoxelSize:float;
@export var treshHold = 0.25;

@export var mountainNoise:FastNoiseLite;
@export var hillNoise:FastNoiseLite;
@export var mountainTerrainNoise:FastNoiseLite;
@export var hillTerrainNoise:FastNoiseLite;
@export var clipNoise:FastNoiseLite;

var surface_array = [];
var Threads = [];

var chunkInfo = [];
var meshInfo = [];
var removeMeshInfo = [];
var builtChunks = [];
var meshedChunks = [];
var currChunks = [];
var collider;
var buildCollider:bool;

var player;
var CollisionShape;
var currentPlayerPos:Vector3;
var previousPlayerPos;
var clearPassedChunks = true;

func _ready():
	player = get_tree().root.get_node("Main").get_node("Entities").get_node("CharacterBody3D");
	CollisionShape = get_parent().get_child(0);
	
	for i in 5:
		Threads.insert(0, Thread.new());
	
	collider = ConcavePolygonShape3D.new();

func _cube_marching_thread(_pos, i):
	var verts:PackedVector3Array = [];
	var tris:PackedInt32Array = []; 
	var normals:PackedVector3Array = [];
	for x in ChunkSize + 1:
		for y in ChunkSize + 1:
			for z in ChunkSize + 1:
				var normalsList = [Vector3(1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, 1)]
				if y == 0 || z == 0:
					normalsList.erase(Vector3(1, 0, 0));
				if x == 0 || z == 0:
					normalsList.erase(Vector3(0, 1, 0));
				if x == 0 || y == 0:
					normalsList.erase(Vector3(0, 0, 1));
				
				var voxelPos = Vector3(x - float(ChunkSize - 1) / 2, y, z - float(ChunkSize - 1) / 2) * VoxelSize - Vector3.ONE;
				
				for face in normalsList:
					var mountainNoiseValue1 = (mountainNoise.get_noise_3d(_pos.x * ChunkSize + x - float(WorldSize.x * ChunkSize) / 2, _pos.y * ChunkSize + y, _pos.z * ChunkSize + z - float(WorldSize.z * ChunkSize) / 2) + 1) / 2 + ((clipNoise.get_noise_2d(_pos.x * ChunkSize + x - float(WorldSize.x * ChunkSize) / 2, _pos.z * ChunkSize + z - (WorldSize.z * ChunkSize) / 2) + 1) / 2 - clamp((_pos.y * ChunkSize + y) * 0.01, 0, 1));
					var mountainNoiseValue2 = (mountainNoise.get_noise_3d(_pos.x * ChunkSize + x + face.x - float(WorldSize.x * ChunkSize) / 2, _pos.y * ChunkSize + y + face.y, _pos.z * ChunkSize + z + face.z - float(WorldSize.z * ChunkSize) / 2) + 1) / 2 + ((clipNoise.get_noise_2d(_pos.x * ChunkSize + x + face.x - float(WorldSize.x * ChunkSize) / 2, _pos.z * ChunkSize + z + face.z - (WorldSize.z * ChunkSize) / 2) + 1) / 2 - clamp((_pos.y * ChunkSize + y + face.y) * 0.01, 0, 1));
					var hillNoiseValue1 = (hillNoise.get_noise_2d(_pos.x * ChunkSize + x - float(WorldSize.x * ChunkSize) / 2, _pos.z * ChunkSize + z - float(WorldSize.z * ChunkSize) / 2) + 1) / 2 - clamp((_pos.y * ChunkSize + y) * 0.01, 0, 1);
					var hillNoiseValue2 = (hillNoise.get_noise_2d(_pos.x * ChunkSize + x + face.x - float(WorldSize.x * ChunkSize) / 2, _pos.z * ChunkSize + z + face.z - float(WorldSize.z * ChunkSize) / 2) + 1) / 2 - clamp((_pos.y * ChunkSize + y + face.y) * 0.01, 0, 1);
					var mountainTerrainValue1 = (mountainTerrainNoise.get_noise_2d(_pos.x * ChunkSize + x - float(ChunkSize) / 2, _pos.z * ChunkSize + z - float(ChunkSize) / 2) + 1) / 2 - clamp((_pos.y * ChunkSize + y) * 0.01, 0, 1);
					var mountainTerrainValue2 = (mountainTerrainNoise.get_noise_2d(_pos.x * ChunkSize + x + face.x - float(ChunkSize) / 2, _pos.z * ChunkSize + z + face.z - float(ChunkSize) / 2) + 1) / 2 - clamp((_pos.y * ChunkSize + y + face.y) * 0.01, 0, 1);
					var hillTerrainValue1 = (hillTerrainNoise.get_noise_2d(_pos.x * ChunkSize + x - float(ChunkSize) / 2, _pos.z * ChunkSize + z - float(ChunkSize) / 2) + 1) / 2 - clamp((_pos.y * ChunkSize + y) * 0.01, 0, 1);
					var hillTerrainValue2 = (hillTerrainNoise.get_noise_2d(_pos.x * ChunkSize + x + face.x - float(ChunkSize) / 2, _pos.z * ChunkSize + z + face.z - float(ChunkSize) / 2) + 1) / 2 - clamp((_pos.y * ChunkSize + y + face.y) * 0.01, 0, 1);
					var terrainValue1 = mountainNoiseValue1 * mountainTerrainValue1 + hillNoiseValue1 * hillTerrainValue1;
					var terrainValue2 = mountainNoiseValue2 * mountainTerrainValue2 + hillNoiseValue2 * hillTerrainValue2;
					#var surface = int(mountainNoiseValue1 > treshHold) - int(mountainNoiseValue2 > treshHold);
					#var surface = int(hillNoiseValue1 + 0.5 > treshHold) - int(hillNoiseValue2 + 0.5 > treshHold);
					var surface = int((hillNoiseValue1 + 0.5 + mountainNoiseValue1) > treshHold) - int((hillNoiseValue2 + 0.5 + mountainNoiseValue2) > treshHold);
					#var surface = int(terrainValue1 + 0.5 > treshHold) - int(terrainValue2 + 0.5 > treshHold);
					if surface != 0:
						var localIndecies = [];
						for j in 2:
							for k in 2:
								var vertLocalPos;
								if face.x != 0:
									vertLocalPos = Vector3(face.x, 2 * k - 1, 2 * j - 1);
								elif face.y != 0:
									vertLocalPos = Vector3(2 * j - 1, face.y, 2 * k - 1);
								elif face.z != 0:
									vertLocalPos = Vector3(2 * k - 1, 2 * j - 1, face.z);
								var vertGlobalPos = ((_pos - Vector3(WorldSize.x - 1, 0, WorldSize.z - 1) / 2) * ChunkSize) + voxelPos + vertLocalPos * VoxelSize / 2;
								if !verts.has(vertGlobalPos):
									verts.append(vertGlobalPos);
									normals.append(face.normalized() * surface);
									localIndecies.append(len(verts) - 1);
								else:
									var prevNormal = normals[verts.find(vertGlobalPos)];
									var currNormal = (face * surface * Vector3(1, 1, -1) * max(abs(normals[verts.find(vertGlobalPos)].x), abs(normals[verts.find(vertGlobalPos)].y), abs(normals[verts.find(vertGlobalPos)].z)));
									normals[verts.find(vertGlobalPos)] = (prevNormal + currNormal).normalized();
									localIndecies.append(verts.find(vertGlobalPos));
						if surface == 1:
							tris.append_array([localIndecies[0], localIndecies[2], localIndecies[3], localIndecies[0], localIndecies[3], localIndecies[1]]);
						elif surface == -1:
							tris.append_array([localIndecies[0], localIndecies[3], localIndecies[2], localIndecies[0], localIndecies[1], localIndecies[3]]);
	if len(verts):
		verts.append((_pos - Vector3(1, 0, 1) * Vector3(WorldSize) / 2) * ChunkSize);
		normals.append(Vector3.UP);
		builtChunks.append(_pos);
	meshInfo.append({"verts": verts, "tris": tris, "normals": normals});
	call_deferred("_remove_thread", i);

func _build_mesh_thread(verts, tris, normals, i):
	if len(verts) > 0:
		surface_array.resize(Mesh.ARRAY_MAX);
		
		surface_array[Mesh.ARRAY_VERTEX] = verts;
#		surface_array[Mesh.ARRAY_TEX_UV] = uvs;
		surface_array[Mesh.ARRAY_NORMAL] = normals;
		surface_array[Mesh.ARRAY_INDEX] = tris;
		call("_add_surface_from_arrays", surface_array);
		call("_add_collider", verts, tris);
	call_deferred("_remove_thread", i);

func _remove_surface_thread(posList, i):
	var surfaces = mesh._get_surfaces();
#	print(posList)
	for pos in posList:
		print("- - - - -")
		print(pos)
		for s in surfaces:
			print(round(s.aabb.position / ChunkSize) + Vector3(1, 0, 1))
			if pos == round(s.aabb.position / ChunkSize) + Vector3(1, 0, 1):
				surfaces.erase(s)
	mesh._set_surfaces(surfaces);
	clearPassedChunks = true;
	call_deferred("_remove_thread", i);

func _add_surface_from_arrays(a):
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, a);

func _add_collider(verts, tris):
	var faces:PackedVector3Array = [];
	for j in tris:
		faces.append(verts[j]);
	collider.set_faces(collider.get_faces() + faces);
	CollisionShape.call("set_shape", collider);

func _remove_thread(t):
	t.wait_to_finish()

func _physics_process(_delta):
	currentPlayerPos = round(player.position / ChunkSize) * Vector3(1, 0, 1);
	currChunks = [];
	
	if currentPlayerPos != previousPlayerPos:
		for x in WorldSize.x:
			for y in WorldSize.y:
				for z in WorldSize.z:
					chunkInfo.append(Vector3(x, y, z) + currentPlayerPos);
					currChunks.append(Vector3(x, y, z) + currentPlayerPos);
		previousPlayerPos = currentPlayerPos;
	
		var c = 0
		while c < len(builtChunks):
			if builtChunks[c] not in currChunks:
				removeMeshInfo.append(builtChunks[c]);
				builtChunks.remove_at(c);
			else:
				if builtChunks[c] in removeMeshInfo:
					removeMeshInfo.erase(builtChunks[c]);
				c += 1;
	
	if len(meshInfo) > 0:
		for i in range(min(len(meshInfo), len(Threads))):
			if !Threads[i].is_started():
				Threads[i].start(_build_mesh_thread.bind(meshInfo[0].verts, meshInfo[0].tris, meshInfo[0].normals, Threads[i]));
				meshInfo.remove_at(0);
	
	if len(removeMeshInfo) > 0 && clearPassedChunks:
		for i in len(Threads):
			if !Threads[i].is_started():
				Threads[i].start(_remove_surface_thread.bind(removeMeshInfo.duplicate(false), Threads[i]));
				removeMeshInfo.clear();
				clearPassedChunks = false;
				break;
	
	if len(chunkInfo) > 0:
		for i in range(min(len(chunkInfo), len(Threads))):
			if !Threads[i].is_started():
				Threads[i].start(_cube_marching_thread.bind(chunkInfo[0], Threads[i]));
				chunkInfo.remove_at(0);
	
#	if buildCollider:
#		CollisionShape.set_shape(collider);
#		buildCollider = false;
	
#	if len(meshInfo) > 0:
#		_build_mesh_thread(meshInfo[0].verts, meshInfo[0].tris);
#		meshInfo.remove_at(0);
#		if len(meshInfo) == 0:
#			collider = mesh.create_trimesh_shape();
#
#			get_parent().get_child(1).set_shape(collider);
