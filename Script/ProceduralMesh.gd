extends CSGMesh3D

@export var WorldSize:Vector3i;
@export var ChunkSize:int;
@export var VoxelSize:float;

var g:int;

var noise = FastNoiseLite.new();
var floorNoise = FastNoiseLite.new();
var treshHold = 0.25;

var surface_array = [];
var verticies:PackedVector3Array;
var tris:PackedInt32Array;

var thread;
var collider;
var createCollider;

var updateMesh:bool;

func _ready():
	mesh = ArrayMesh.new();
	thread = Thread.new();
	thread.start(Callable(self, "_thread_function"), 0);

func _thread_function():
	for wx in WorldSize.x:
		for wy in WorldSize.y:
			for wz in WorldSize.z:
				var _pos = Vector3(wx, wy, wz);
				for x in ChunkSize + 1:
					for y in ChunkSize + 1:
						for z in ChunkSize + 1:
							var normals = [Vector3(1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, 1)]
							if y == 0 || z == 0:
								normals.erase(Vector3(1, 0, 0));
							if x == 0 || z == 0:
								normals.erase(Vector3(0, 1, 0));
							if x == 0 || y == 0:
								normals.erase(Vector3(0, 0, 1));
							
							var voxelPos = Vector3(x - float(ChunkSize - 1) / 2, y, z - float(ChunkSize - 1) / 2) * VoxelSize - Vector3.ONE;
							
							for face in normals:
								var noiseValue1 = noise.get_noise_3d(_pos.x * ChunkSize + x, _pos.y * ChunkSize + y, _pos.z * ChunkSize + z);
								var noiseValue2 = noise.get_noise_3d(_pos.x * ChunkSize + x + face.x, _pos.y * ChunkSize + y + face.y, _pos.z * ChunkSize + z + face.z);
								var floorValue1 = floorNoise.get_noise_2d(_pos.x * ChunkSize + x - float(ChunkSize) / 2, _pos.z * ChunkSize + z - float(ChunkSize) / 2);
								var floorValue2 = floorNoise.get_noise_2d(_pos.x * ChunkSize + x + face.x - float(ChunkSize) / 2, _pos.z * ChunkSize + z + face.z - float(ChunkSize) / 2);
								var surface = int(noiseValue1 + clamp((floorValue1 + 1.1) - (_pos.y * ChunkSize + y) * 0.1, 0, 1) > treshHold) - int(noiseValue2 + clamp((floorValue2 + 1.1) - (_pos.y * ChunkSize + y + face.y) * 0.1, 0, 1) > treshHold);
								#surface = int(noiseValue1 > treshHold) - int(noiseValue2 > treshHold);
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
									g += 3
								g += 1
	updateMesh = true;

func _exit_tree():
	thread.wait_to_finish();

func _physics_process(delta):
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
		print(g)
