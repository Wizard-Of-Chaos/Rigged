class_name MoveController
extends Node

signal move_state_set(MoveState)
signal actor_state_set(ActorStateChange)

@export var current_actor_state: ActorState
@export var old_actor_state: ActorState
@export var rotation_speed: float = 8
@export var direction: Vector3
@export var acceleration: float
@export var speed: float
@export var rotation: float = 0

var up: Vector3 = Vector3.UP
var jump_speed = 1200
var fall_speed = 40
var grounded := true

func get_state_change(new_state: ActorState) -> ActorStateChange:
	var ret: ActorStateChange = ActorStateChange.new()
	ret.old_state = old_actor_state
	ret.new_state = new_state
	return ret

func set_move_state(p_move_state: MoveState):
	speed = p_move_state.speed
	acceleration = p_move_state.acceleration
	rotation_speed = p_move_state.rotation_speed
	grounded = p_move_state.grounded
	move_state_set.emit(p_move_state)

func set_actor_state(p_actorstate: ActorState):
	old_actor_state = current_actor_state
	current_actor_state = p_actorstate
	actor_state_set.emit(get_state_change(p_actorstate))

func set_move_dir(p_direction: Vector3):
	direction = p_direction.rotated(up, rotation)

func set_rotation(p_rotation: float):
	rotation = p_rotation

func get_velocity(is_on_floor: bool) -> Vector3:
	var res: Vector3 = direction
	if not res.is_zero_approx() and res.length_squared() > 1:
		res = res.normalized()
	if grounded:
		res.x *= speed
		if not is_on_floor:
			res.y *= fall_speed
		elif direction.y > 0:
			res.y *= jump_speed
		res.z *= speed
	else:
		res *= speed
	return res
