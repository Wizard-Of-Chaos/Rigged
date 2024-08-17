extends CharacterBody3D

@export var speed: float = 14
@export var accel: float = 80
@export var fall_acceleration: float = 75
@export var jump_impulse: float = 40

@onready var camera_yaw: Node3D = $CamRig/CameraRoot/CamYaw
@onready var camera_root: Node3D = $CamRig/CameraRoot

var target_velocity := Vector3.ZERO
var cam_offset: Vector3

func _ready() -> void:
	cam_offset = camera_root.position

func _physics_process(delta: float) -> void:
	var direction := Vector3.ZERO
	if Input.is_action_pressed("move_left"):
		direction.x += Input.get_action_strength("move_left")
	if Input.is_action_pressed("move_right"):
		direction.x -= Input.get_action_strength("move_right")
	if Input.is_action_pressed("move_up"):
		direction.z += Input.get_action_strength("move_up")
	if Input.is_action_pressed("move_down"):
		direction.z -= Input.get_action_strength("move_down")
	var jump := Input.is_action_pressed("jump")
	if direction.length_squared() > 1:
		direction = direction.normalized()
	basis = camera_yaw.basis
	if not basis.z.is_equal_approx(Vector3.MODEL_FRONT):
		var axis := Vector3.MODEL_FRONT.cross(basis.z).normalized()
		direction = direction.rotated(axis, Vector3.MODEL_FRONT.angle_to(basis.z))
	
	target_velocity.x = move_toward(velocity.x, direction.x * speed, accel * delta)
	target_velocity.z = move_toward(velocity.z, direction.z * speed, accel * delta)
	
	if not is_on_floor():
		target_velocity.y = target_velocity.y - (fall_acceleration * delta)
	elif jump:
		target_velocity.y = jump_impulse
	
	velocity = target_velocity
	if target_velocity.is_zero_approx():
		return
	move_and_slide()
	camera_root.position = position + cam_offset
