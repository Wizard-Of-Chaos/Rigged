extends CharacterBody3D
class_name BaseActor
@onready var health_node = %Health

@onready var mesh_root: Node3D = %MeshRoot

#set this by each individual actor
var anim_tree: AnimationTree

@onready var remote_transform: RemoteTransform3D = %RemoteTransform
@onready var anim_controller: AnimationController = %AnimController
@onready var move_controller: MoveController = %MoveController

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

func set_floating(p_floating: bool) -> void:
	_floating = p_floating
	if _floating:
		motion_mode = MotionMode.MOTION_MODE_FLOATING
	else:
		motion_mode = MotionMode.MOTION_MODE_GROUNDED

func _on_health_changed(old: int, new: int):
	print("%s took damage - %s to %s" % [name, old, new])

func basic_movement(delta: float):
	if moving():
		move_controller.set_move_dir(move_direction)
		if _jumped:
			anim_controller.anim_tree["parameters/jump/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
		if !is_on_floor():
			move_controller.set_move_state(MoveStateList.floating if _floating else MoveStateList.jump)
		else:
			move_controller.set_move_state(MoveStateList.sprint if _sprinting else MoveStateList.run)
	else:
		#move_controller.set_move_dir(Vector3(0,0,0))
		move_controller.set_move_state(MoveStateList.floating if _floating else MoveStateList.idle)

	var target_rotation: float = atan2(move_controller.direction.x, move_controller.direction.z) - rotation.y
	mesh_root.rotation.y = lerp_angle(mesh_root.rotation.y, target_rotation, move_controller.rotation_speed * delta)
	velocity = velocity.lerp(move_controller.get_velocity(is_on_floor()), move_controller.acceleration * delta)

	_jumped = false

	move_and_slide()

func _physics_process(delta: float):
	basic_movement(delta)
