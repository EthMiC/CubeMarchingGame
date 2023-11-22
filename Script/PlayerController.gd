extends CharacterBody3D

@export var SPEED = 4.317
@export var SPRINT_SPEED = 5.612
@export var JUMP_VELOCITY = 11.2
@export var accel:float;
@export var deccel:float;

@export var sensitivity:float;


var started = false;
var front:float;
var right:float;

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")


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

func _input(event):
	if event is InputEventMouseMotion && started:
		rotate_y(deg_to_rad(-event.relative.x * sensitivity));
		get_child(1).rotate_x(deg_to_rad(-event.relative.y * sensitivity));
#		get_child(1).rotation.x = clamp(rotation.x, deg_to_rad(-45), deg_to_rad(45));
