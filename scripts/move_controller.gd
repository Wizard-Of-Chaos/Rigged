class_name MoveController

signal movestate_set(MoveState)

@export var rotation_speed: float = 8
var direction: Vector3
var velocity: Vector3
var acceleration: float
var speed: float
var rotation: float = 0
var up: Vector3 = Vector3.UP

func set_movestate(p_movestate: MoveState):
	speed = p_movestate.speed
	acceleration = p_movestate.acceleration
	movestate_set.emit(p_movestate)

func set_move_dir(p_direction: Vector3):
	direction = p_direction.rotated(up, rotation)

func set_rotation(p_rotation: float):
	rotation = p_rotation

func get_velocity():
	var res: Vector3 = direction
	if not res.is_zero_approx() and res.length_squared() > 1:
		res = res.normalized()
	
	res.x *= speed
	res.z *= speed
	return res
