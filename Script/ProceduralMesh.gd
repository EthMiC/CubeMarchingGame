extends CSGMesh3D

@export var genMesh: bool: set = GenInViewport

@export var GridSize:int;
@export var VoxelSize:float;

var noise = FastNoiseLite.new();
var floor = FastNoiseLite.new();
var treshHold = 0.25;

var surface_array = [];
var verticies:PackedVector3Array;
var tris:PackedInt32Array;

var thread;
var collider;

func _ready():
	thread = Thread.new();
	thread.start(Callable(self, "_thread_function"), 0);
	

func GenInViewport(__):
	print("oop")

func _thread_function():
	for x in GridSize + 1:
		for y in GridSize + 1:
			for z in GridSize + 1:
				call_deferred("set_scale", Vector3(((x + y + z) / (GridSize * 3)), 1, 1))
				var normals = [Vector3(1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, 1)]
				if y == 0 || z == 0:
					normals.erase(Vector3(1, 0, 0));
				if x == 0 || z == 0:
					normals.erase(Vector3(0, 1, 0));
				if x == 0 || y == 0:
					normals.erase(Vector3(0, 0, 1));
				
				var voxelPos = Vector3(x - float(GridSize - 1) / 2, y, z - float(GridSize - 1) / 2) * VoxelSize - Vector3.ONE;
				
				for face in normals:
					var surface = getState(x, y, z, treshHold) - getState(x + face.x, y + face.y, z + face.z, treshHold);
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
								var vertGlobalPos = voxelPos + vertLocalPos * VoxelSize / 2;
								if !verticies.has(vertGlobalPos):
									verticies.append(vertGlobalPos);
									localIndecies.append(len(verticies) - 1);
								else:
									localIndecies.append(verticies.find(vertGlobalPos));
						if surface == 1:
							tris.append_array([localIndecies[0], localIndecies[2], localIndecies[3], localIndecies[0], localIndecies[3], localIndecies[1]]);
						elif surface == -1:
							tris.append_array([localIndecies[0], localIndecies[3], localIndecies[2], localIndecies[0], localIndecies[1], localIndecies[3]]);
	
	if len(verticies):
		mesh = ArrayMesh.new();
		
		surface_array.resize(Mesh.ARRAY_MAX);
		
		surface_array[Mesh.ARRAY_VERTEX] = verticies;
		#surface_array[Mesh.ARRAY_TEX_UV] = uvs;
		#surface_array[Mesh.ARRAY_NORMAL] = normals;
		surface_array[Mesh.ARRAY_INDEX] = tris;
	
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array);

func _exit_tree():
	thread.wait_to_finish();

func _process(delta):
	if mesh != null && collider == null:
		collider = mesh.create_trimesh_shape();
		
		get_parent().get_child(1).shape = collider;

func getState(_x, _y, _z, _pass):
	var floorValue = floor.get_noise_2d(_x, _z);
	return int(noise.get_noise_3dv(Vector3(_x, _y, _z)) + clamp((floorValue + 1.1) - _y * 0.1, 0, 1) > _pass);
