extends CharacterBody3D

@export var speed: float = 14
@export var fall_acceleration: float = 75
@export var jump_impulse: float = 40

var target_velocity := Vector3.ZERO

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
	
	target_velocity.x = direction.x * speed
	target_velocity.z = direction.z * speed
	
	if not is_on_floor():
		target_velocity.y = target_velocity.y - (fall_acceleration * delta)
	elif jump:
		target_velocity.y = jump_impulse
	
	velocity = target_velocity
	move_and_slide()
