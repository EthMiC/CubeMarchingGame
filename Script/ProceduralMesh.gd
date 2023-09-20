extends CSGMesh3D

@export var GridSize:int;
@export var VoxelSize:float;

var noise = NoiseTexture3D.new();
var treshHold = 0.25;

var surface_array = [];
var vertexDictionary = {};
var faceDictionary = {};
var verticies:PackedVector3Array;
var tris:PackedInt32Array;

func _ready():
	noise.noise = FastNoiseLite.new();
	for x in GridSize + 1:
		for y in GridSize + 1:
			for z in GridSize + 1:
				var normals = [Vector3(1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, 1)]
				if y == 0 || z == 0:
					normals.erase(Vector3(1, 0, 0));
				if x == 0 || z == 0:
					normals.erase(Vector3(0, 1, 0));
				if x == 0 || y == 0:
					normals.erase(Vector3(0, 0, 1));
				print(normals)
				
				var voxelPos = Vector3(x - float(GridSize - 1) / 2, y - float(GridSize - 1) / 2, z - float(GridSize - 1) / 2) * VoxelSize - Vector3.ONE;
				
				for face in normals:
					var surface = getNoisePass(x, y, z, treshHold) - getNoisePass(x + face.x, y + face.y, z + face.z, treshHold);
					if surface != 0:
						var parentVoxelPos = voxelPos + ((face / 2) - (abs(face) / 2))
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
								if !vertexDictionary.has(vertGlobalPos):
									verticies.append(vertGlobalPos);
									vertexDictionary[vertGlobalPos] = len(verticies) - 1;
									localIndecies.append(len(verticies) - 1);
								else:
									localIndecies.append(vertexDictionary[vertGlobalPos]);
						if surface == 1:
							tris.append_array([localIndecies[0], localIndecies[2], localIndecies[3], localIndecies[0], localIndecies[3], localIndecies[1]]);
						elif surface == -1:
							tris.append_array([localIndecies[0], localIndecies[3], localIndecies[2], localIndecies[0], localIndecies[1], localIndecies[3]]);
	
	for v in verticies:
		var point = CSGSphere3D.new();
		point.translate(v);
		point.scale = Vector3.ONE * .25;
		#add_child(point);
	
	if len(verticies):
		mesh = ArrayMesh.new();
		
		surface_array.resize(Mesh.ARRAY_MAX);
		
		surface_array[Mesh.ARRAY_VERTEX] = verticies;
		#surface_array[Mesh.ARRAY_TEX_UV] = uvs;
		#surface_array[Mesh.ARRAY_NORMAL] = normals;
		surface_array[Mesh.ARRAY_INDEX] = tris;
	
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array);
	
	print(len(tris) / 6);

func _process(delta):
	pass

func getNoisePass(_x, _y, _z, _pass):
	return int(noise.noise.get_noise_3dv(Vector3(_x, _y, _z)) > _pass);
