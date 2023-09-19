extends Node3D

@export var GridSize:int;
@export var VoxelSize:float;

func _ready():
	for x in GridSize:
		for y in GridSize:
			for z in GridSize:
				var point = CSGBox3D.new();
				point.translate(Vector3(x - GridSize / 2, y - GridSize / 2, z - GridSize / 2) * VoxelSize);
				add_child(point);

func _process(delta):
	pass
