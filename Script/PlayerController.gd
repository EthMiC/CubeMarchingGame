extends CharacterBody3D

@export var SPEED = 4.317
@export var SPRINT_SPEED = 5.612
@export var JUMP_VELOCITY = 11.2
@export var accel:float;
@export var deccel:float;

@export var sensitivity:float;

var rayCast:RayCast3D;
var cam:Camera3D;
var world:MeshInstance3D;

var started = false;
var front:float;
var right:float;

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready():
	rayCast = get_child(0).get_child(0);
	cam = get_child(1);
	world = get_node("/root/Main/PhysicalObjects/ProceduralMesh/Ground")

func _physics_process(delta):
	if Input.is_action_just_pressed("ui_text_completion_accept"):
		started = !started
		get_child(1).current = !get_child(1).current
	
	if !started:
		return;      
	
	var dir = transform.basis.z;
	
	var frontInput = float(Input.is_key_pressed(KEY_W)) - float(Input.is_key_pressed(KEY_S));
	var rightInput = float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A));
	
	var frontDir = frontInput - front;
	if frontInput != 0:
		front += min(abs(frontDir), (1 / accel) * delta) * ceil(abs(frontDir)) * sign(frontDir);
	else:
		front += min(abs(frontDir), (1 / deccel) * delta) * ceil(abs(frontDir)) * sign(frontDir);
	
	var rightDir = rightInput - right;
	if rightInput != 0:
		right += min(abs(rightDir), (1 / accel) * delta) * ceil(abs(rightDir)) * sign(rightDir);
	else:
		right += min(abs(rightDir), (1 / deccel) * delta) * ceil(abs(rightDir)) * sign(rightDir);
	
	var vel_vector = ((dir * front) + (dir.cross(Vector3.UP) * right));
	
	velocity.x = -min(abs(vel_vector.x), abs(vel_vector.normalized().x)) * sign(vel_vector.x);
	velocity.z = -min(abs(vel_vector.z), abs(vel_vector.normalized().z)) * sign(vel_vector.z);
	
	if Input.is_action_pressed("ui_shift"):
		velocity *= Vector3(SPRINT_SPEED, 1, SPRINT_SPEED);
	else:
		velocity *= Vector3(SPEED, 1, SPEED);
	
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
	
	# Handle Jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	move_and_slide()
	
	rayCast.target_position = -cam.get_basis().z * 5;
	if rayCast.is_colliding():
		cam.get_child(0).set_global_position(round(rayCast.get_collision_point() - rayCast.get_collision_normal() / 2));
		cam.get_child(0).set_global_rotation(Vector3.ZERO);
	else:
		cam.get_child(0).position = Vector3.ZERO;

func _input(event):
	if started:
		if event is InputEventMouseMotion:
			rotate_y(deg_to_rad(-event.relative.x * sensitivity));
			cam.rotate_x(deg_to_rad(-event.relative.y * sensitivity));
			#cam.rotation.x = clamp(rotation.x, deg_to_rad(0), deg_to_rad(180));
		if event.is_pressed() && event is InputEventMouseButton && rayCast.is_colliding():
			if event.button_index == MOUSE_BUTTON_LEFT:
				world.updateChunk(round(rayCast.get_collision_point() - rayCast.get_collision_normal() / 2), false);
			if event.button_index == MOUSE_BUTTON_RIGHT:
				world.updateChunk(round(rayCast.get_collision_point() + rayCast.get_collision_normal() / 2), true);
