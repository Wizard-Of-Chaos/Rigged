class_name MoveController
extends Node

signal move_state_set(MoveState)
signal actor_state_set(ActorStateChange)

@export var current_actor_state: ActorState
@export var old_actor_state: ActorState
@export var direction: Vector3
@export var rotation: float = 0

var up: Vector3 = Vector3.UP
var previous_move_state: MoveState = MoveStateList.idle
var current_move_state: MoveState = MoveStateList.idle

func get_state_change(new_state: ActorState) -> ActorStateChange:
	var ret: ActorStateChange = ActorStateChange.new()
	ret.old_state = old_actor_state
	ret.new_state = new_state
	return ret

func move_state():
	return current_move_state
	
func actor_state():
	return current_actor_state
	
func set_move_state(p_move_state: MoveState):
	previous_move_state = current_move_state
	current_move_state = p_move_state
	move_state_set.emit(p_move_state)

func set_actor_state(p_actorstate: ActorState):
	old_actor_state = current_actor_state
	current_actor_state = p_actorstate
	actor_state_set.emit(get_state_change(p_actorstate))

func set_move_dir(p_direction: Vector3):
	direction = p_direction.rotated(up, rotation)

func set_rotation(p_rotation: float):
	rotation = p_rotation

func get_desired_velocity() -> Vector3:
	var res: Vector3 = direction
	if not res.is_zero_approx() and res.length_squared() > 1:
		res = res.normalized()
	if current_actor_state == ActorStateList.floating:
		res.y *= current_move_state.speed * current_actor_state.speed_multiplier
	res.x *= current_move_state.speed * current_actor_state.speed_multiplier
	res.z *= current_move_state.speed * current_actor_state.speed_multiplier
	return res
