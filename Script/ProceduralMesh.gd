extends CSGMesh3D

@export var WorldSize:Vector3i;
@export var ChunkSize:int;
@export var VoxelSize:float;
@export var treshHold = 0.25;

@export var mountainNoise:FastNoiseLite;
@export var hillNoise:FastNoiseLite;
@export var mountainTerrainNoise:FastNoiseLite;
@export var hillTerrainNoise:FastNoiseLite;
@export var clipNoise:FastNoiseLite;

@export var playerPosition:Vector3;

var surface_array = [];
var verticies:PackedVector3Array;
var tris:PackedInt32Array;

var thread;
var collider;
var createCollider;

var updateMesh:bool;
var updatePercentage = true;

var percentage:float;

func _ready():
	mesh = ArrayMesh.new();
	thread = Thread.new();
	thread.start(Callable(self, "_thread_function"), 0);

func _thread_function():
	for wx in WorldSize.x:
		for wy in WorldSize.y:
			for wz in WorldSize.z:
				var _pos = Vector3(wx, wy, wz);
				playerPosition *= Vector3(1, 0, 1);
				for x in ChunkSize + 1:
					for y in ChunkSize + 1:
						for z in ChunkSize + 1:
							percentage = ((wx * WorldSize.y * WorldSize.z * pow(ChunkSize, 3)) + (wy * WorldSize.z * pow(ChunkSize, 3)) + (wz * pow(ChunkSize, 3)) + (x * pow(ChunkSize, 2)) + (y * ChunkSize) + z) / (WorldSize.x * WorldSize.y * WorldSize.z * pow(ChunkSize, 3));
							var normals = [Vector3(1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, 1)]
							if y == 0 || z == 0:
								normals.erase(Vector3(1, 0, 0));
							if x == 0 || z == 0:
								normals.erase(Vector3(0, 1, 0));
							if x == 0 || y == 0:
								normals.erase(Vector3(0, 0, 1));
							
							var voxelPos = Vector3(x - float(ChunkSize - 1) / 2, y, z - float(ChunkSize - 1) / 2) * VoxelSize - Vector3.ONE;
							
							for face in normals:
								var mountainNoiseValue1 = (mountainNoise.get_noise_3d(_pos.x * ChunkSize + x, _pos.y * ChunkSize + y, _pos.z * ChunkSize + z) + 1) / 2 + ((clipNoise.get_noise_2d(_pos.x * ChunkSize + x - float(ChunkSize) / 2, _pos.z * ChunkSize + z - float(ChunkSize) / 2) + 1) / 2 - clamp((_pos.y * ChunkSize + y) * 0.01, 0, 1));
								var mountainNoiseValue2 = (mountainNoise.get_noise_3d(_pos.x * ChunkSize + x + face.x, _pos.y * ChunkSize + y + face.y, _pos.z * ChunkSize + z + face.z) + 1) / 2 + ((clipNoise.get_noise_2d(_pos.x * ChunkSize + x + face.x - float(ChunkSize) / 2, _pos.z * ChunkSize + z + face.z - float(ChunkSize) / 2) + 1) / 2 - clamp((_pos.y * ChunkSize + y + face.y) * 0.01, 0, 1));
								var hillNoiseValue1 = (hillNoise.get_noise_2d(_pos.x * ChunkSize + x, _pos.z * ChunkSize + z) + 1) / 2 - clamp((_pos.y * ChunkSize + y) * 0.01, 0, 1);
								var hillNoiseValue2 = (hillNoise.get_noise_2d(_pos.x * ChunkSize + x + face.x, _pos.z * ChunkSize + z + face.z) + 1) / 2 - clamp((_pos.y * ChunkSize + y + face.y) * 0.01, 0, 1);
								var mountainTerrainValue1 = (mountainTerrainNoise.get_noise_2d(_pos.x * ChunkSize + x - float(ChunkSize) / 2, _pos.z * ChunkSize + z - float(ChunkSize) / 2) + 1) / 2 - clamp((_pos.y * ChunkSize + y) * 0.01, 0, 1);
								var mountainTerrainValue2 = (mountainTerrainNoise.get_noise_2d(_pos.x * ChunkSize + x + face.x - float(ChunkSize) / 2, _pos.z * ChunkSize + z + face.z - float(ChunkSize) / 2) + 1) / 2 - clamp((_pos.y * ChunkSize + y + face.y) * 0.01, 0, 1);
								var hillTerrainValue1 = (hillTerrainNoise.get_noise_2d(_pos.x * ChunkSize + x - float(ChunkSize) / 2, _pos.z * ChunkSize + z - float(ChunkSize) / 2) + 1) / 2 - clamp((_pos.y * ChunkSize + y) * 0.01, 0, 1);
								var hillTerrainValue2 = (hillTerrainNoise.get_noise_2d(_pos.x * ChunkSize + x + face.x - float(ChunkSize) / 2, _pos.z * ChunkSize + z + face.z - float(ChunkSize) / 2) + 1) / 2 - clamp((_pos.y * ChunkSize + y + face.y) * 0.01, 0, 1);
								var terrainValue1 = mountainNoiseValue1 * mountainTerrainValue1 + hillNoiseValue1 * hillTerrainValue1;
								var terrainValue2 = mountainNoiseValue2 * mountainTerrainValue2 + hillNoiseValue2 * hillTerrainValue2;
								#var surface = int(mountainNoiseValue1 > treshHold) - int(mountainNoiseValue2 > treshHold);
								#var surface = int(hillNoiseValue1 + 0.5 > treshHold) - int(hillNoiseValue2 + 0.5 > treshHold);
								var surface = int((hillNoiseValue1 + 0.5 + terrainValue1) > treshHold) - int((hillNoiseValue2 + 0.5 + terrainValue2) > treshHold);
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
											if !verticies.has(vertGlobalPos):
												verticies.append(vertGlobalPos);
												localIndecies.append(len(verticies) - 1);
											else:
												localIndecies.append(verticies.find(vertGlobalPos));
									if surface == 1:
										tris.append_array([localIndecies[0], localIndecies[2], localIndecies[3], localIndecies[0], localIndecies[3], localIndecies[1]]);
									elif surface == -1:
										tris.append_array([localIndecies[0], localIndecies[3], localIndecies[2], localIndecies[0], localIndecies[1], localIndecies[3]]);
	updateMesh = true;

func _gen_mesh():
	mesh.clear_surfaces();
	
	for x in ChunkSize * WorldSize.x:
		for z in ChunkSize * WorldSize.z:
			percentage = ((x * WorldSize.z * ChunkSize) + z) / (WorldSize.x * WorldSize.z * pow(ChunkSize, 2));
			#var mountainNoiseValue1 = (mountainNoise.get_noise_3d(x, 0, z) + 1) / 2;
			#var mountainNoiseValue2 = (mountainNoise.get_noise_3d(_pos.x * ChunkSize + x + face.x, _pos.y * ChunkSize + y + face.y, _pos.z * ChunkSize + z + face.z) + 1) / 2 + ((clipNoise.get_noise_2d(_pos.x * ChunkSize + x + face.x - float(ChunkSize) / 2, _pos.z * ChunkSize + z + face.z - float(ChunkSize) / 2) + 1) / 2 - clamp((_pos.y * ChunkSize + y + face.y) * 0.01, 0, 1));
			var hillNoiseValue1 = (hillNoise.get_noise_2d(x, z) + 1) / 2
			#var hillNoiseValue2 = (hillNoise.get_noise_3d(_pos.x * ChunkSize + x + face.x, _pos.y * ChunkSize + y + face.y, _pos.z * ChunkSize + z + face.z) + 1) / 2
			#var mountainTerrainValue1 = (mountainTerrainNoise.get_noise_2d(x - float(ChunkSize) / 2, z - float(ChunkSize) / 2) + 1) / 2;
			#var mountainTerrainValue2 = (mountainTerrainNoise.get_noise_2d(_pos.x * ChunkSize + x + face.x - float(ChunkSize) / 2, _pos.z * ChunkSize + z + face.z - float(ChunkSize) / 2) + 1) / 2 - clamp((_pos.y * ChunkSize + y + face.y) * 0.01, 0, 1);
			var hillTerrainValue1 = (hillTerrainNoise.get_noise_2d(x - float(ChunkSize) / 2,z - float(ChunkSize) / 2) + 1) / 2;
			#var hillTerrainValue2 = (hillTerrainNoise.get_noise_2d(_pos.x * ChunkSize + x + face.x - float(ChunkSize) / 2, _pos.z * ChunkSize + z + face.z - float(ChunkSize) / 2) + 1) / 2 - clamp((_pos.y * ChunkSize + y + face.y) * 0.01, 0, 1);
			var terrainValue1 = hillNoiseValue1 * hillTerrainValue1;
			#var terrainValue2 = mountainNoiseValue2 * mountainTerrainValue2 + hillNoiseValue2 * hillTerrainValue2;
			#var thisHeight = noise.get_noise_2d(x * xScale, z * zScale) * height;
			verticies.append(Vector3((x * VoxelSize) - ((ChunkSize * WorldSize.x - 1) * VoxelSize)/2, terrainValue1, (z * VoxelSize) - ((ChunkSize * WorldSize.z - 1) * VoxelSize)/2) * Vector3(2, 200, 2));
			#uvs.append(Vector2((x - (xGrid - 1)/2), (z - (zGrid - 1)/2)) * 2);
			#var xVn = Vector3(-1, noise.get_noise_2d((x - 1) * xScale, z * zScale) * height - thisHeight, 0);
			#var xVp = Vector3(1, noise.get_noise_2d((x + 1) * xScale, z * zScale) * height - thisHeight, 0);
			#var zVn = Vector3(0, noise.get_noise_2d(x * xScale, (z - 1) * zScale) * height - thisHeight, -1);
			#var zVp = Vector3(0, noise.get_noise_2d(x * xScale, (z + 1) * zScale) * height - thisHeight, 1);
			#normals.append(xVn.cross(zVn));
	
	for x in ChunkSize * WorldSize.x - 1:
		for z in ChunkSize * WorldSize.z - 1:
			tris.append((x + (z * ChunkSize * WorldSize.x)));
			tris.append((x + (z * ChunkSize * WorldSize.x)) + ChunkSize * WorldSize.x);
			tris.append((x + (z * ChunkSize * WorldSize.x)) + ChunkSize * WorldSize.x + 1);
			tris.append((x + (z * ChunkSize * WorldSize.x)));
			tris.append((x + (z * ChunkSize * WorldSize.x)) + ChunkSize * WorldSize.x + 1);
			tris.append((x + (z * ChunkSize * WorldSize.x)) + 1);
	updateMesh = true;

func _exit_tree():
	thread.wait_to_finish();

func _physics_process(delta):
	if updatePercentage:
		get_child(0).size = Vector3(percentage * 30, 1, 1);
	if updateMesh:
		if len(verticies):		
			surface_array.resize(Mesh.ARRAY_MAX);
			
			surface_array[Mesh.ARRAY_VERTEX] = verticies;
			#surface_array[Mesh.ARRAY_TEX_UV] = uvs;
			#surface_array[Mesh.ARRAY_NORMAL] = normals;
			surface_array[Mesh.ARRAY_INDEX] = tris;
			
			mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array);
		collider = mesh.create_trimesh_shape();
		
		get_parent().get_child(1).shape = collider;
		updateMesh = false;
		updatePercentage = false;
