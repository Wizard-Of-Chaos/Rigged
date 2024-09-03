class_name MoveController
extends Node

signal movestate_set(MoveState)

@export var rotation_speed: float = 8
@export var direction: Vector3
@export var acceleration: float
@export var speed: float
@export var rotation: float = 0
var up: Vector3 = Vector3.UP
var jump_speed = 1200
var fall_speed = 40


func set_movestate(p_movestate: MoveState):
	speed = p_movestate.speed
	acceleration = p_movestate.acceleration
	rotation_speed = p_movestate.rotation_speed
	movestate_set.emit(p_movestate)

func set_move_dir(p_direction: Vector3):
	direction = p_direction.rotated(up, rotation)

func set_rotation(p_rotation: float):
	rotation = p_rotation

func get_velocity(is_on_floor: bool) -> Vector3:
	var res: Vector3 = direction
	if not res.is_zero_approx() and res.length_squared() > 1:
		res = res.normalized()
	
	res.x *= speed
	if not is_on_floor:
		res.y *= fall_speed
	elif direction.y > 0:
		res.y *= jump_speed
	res.z *= speed
	return res
