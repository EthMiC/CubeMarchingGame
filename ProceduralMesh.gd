extends Node3D

@export var GridSize:int;
@export var VoxelSize:float;

var noise = NoiseTexture3D.new();

func _ready():
	noise.noise = FastNoiseLite.new();
	for x in GridSize:
		for y in GridSize:
			for z in GridSize:
				var point = CSGBox3D.new();
				point.translate(Vector3(x - GridSize / 2, y - GridSize / 2, z - GridSize / 2) * VoxelSize);
				if noise.noise.get_noise_3d(x, y, z) > 0.5:
					add_child(point);

func _process(delta):
	pass
