extends Node3D

@export var sensitivity:float;
@export var zoom:float;

var rotationY = 0;
var drag = false;

func _input(event):
	if event is InputEventMouseMotion && drag:
		rotate(Vector3.UP, deg_to_rad(-event.relative.x * sensitivity));
		rotationY -= deg_to_rad(-event.relative.x * sensitivity);
		rotate(Vector3(cos(rotationY), 0, sin(rotationY)), deg_to_rad(-event.relative.y * sensitivity));
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				drag = true;
			else:
				drag = false;
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			get_child(0).position *= 1 - zoom;
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			get_child(0).position *= 1 + zoom;
