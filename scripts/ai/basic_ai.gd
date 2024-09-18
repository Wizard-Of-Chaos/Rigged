extends CharacterBody3D
class_name BasicAI

@export var move_states: Dictionary
@export var ai_states: Dictionary
@onready var move_controller: MoveController = %MoveController
@onready var anim_controller: AnimationController = %AnimController
@onready var mesh_root: Node3D = %MeshRoot
@export var current_ai_state: AIState
var _pursuit_target: CharacterBody3D

var move_direction: Vector3: 
	get:
		var dir := Vector3.ZERO
		dir.x = _left_strength - _right_strength
		dir.z = _forward_strength - _back_strength
		if _jumped:
			dir.y = 1.0
		elif _floating:
			dir.y = _up_strength - _down_strength
		elif not is_on_floor():
			dir.y = -1.0
		else:
			dir.y = 0.0
		return dir
		
var _right_strength: float = 0.0
var _left_strength: float = 0.0
var _forward_strength: float = 0.0
var _back_strength: float = 0.0
var _up_strength: float = 0.0
var _down_strength: float = 0.0
var _sprinting: bool = false
var _jumped: bool = false
var _floating: bool = false

func moving() -> bool:
	return abs(move_direction.x) > 0 or abs(move_direction.y) > 0 or abs(move_direction.z) > 0

func _on_body_entered(body: Node3D):
	print("Player...?")
	if body.has_node("Health"):
		print("Player!!!!!!!")
		current_ai_state = ai_states["pursuit"]
		_pursuit_target = body
		
func _on_body_exited(body: Node3D):
	if body.has_node("Health"):
		current_ai_state = ai_states["idle"]
		_pursuit_target = null

func _physics_process(delta: float):
	var move_dir = move_direction
	if current_ai_state.name == "pursuit":
		_forward_strength = 1.0
		move_dir = _pursuit_target.global_position - global_position
		if move_dir.length() < 6.0:
			_forward_strength = 0
		move_dir = move_dir.normalized()
		move_dir.y = 0
	else:
		_forward_strength = 0.0
			
	if moving():
		move_controller.set_move_dir(move_dir)
		move_controller.set_move_state(move_states["run"])
	else:
		move_controller.set_move_dir(Vector3(0,0,0))
		move_controller.set_move_state(move_states["idle"])
	var target_rotation: float = atan2(move_controller.direction.x, move_controller.direction.z) - rotation.y
	mesh_root.rotation.y = lerp_angle(mesh_root.rotation.y, target_rotation, move_controller.rotation_speed * delta)
	velocity = velocity.lerp(move_controller.get_velocity(is_on_floor()), move_controller.acceleration * delta)
	_jumped = false
	move_and_slide()
