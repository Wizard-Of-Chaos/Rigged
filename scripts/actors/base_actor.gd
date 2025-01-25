extends CharacterBody3D
class_name BaseActor
@onready var health_node = %Health

@onready var mesh_root: Node3D = %MeshRoot

#set this by each individual actor
var anim_tree: AnimationTree

@onready var remote_transform: RemoteTransform3D = %RemoteTransform
@onready var anim_controller: AnimationController = %AnimController
@onready var move_controller: MoveController = %MoveController
@onready var collider: CollisionShape3D = %Collider

var move_direction: Vector3: 
	get:
		var dir := Vector3.ZERO
		dir.x = _left_strength - _right_strength
		dir.z = _forward_strength - _back_strength
		if _jumped:
			dir.y = 1.0
		elif move_controller.actor_state() == ActorStateList.floating:
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

#purely for convenience and brevity
var actor_state: ActorState:
	get:
		return move_controller.actor_state()

const _gravity_force: float = -9.81

func moving() -> bool:
	return abs(move_direction.x) > 0 or abs(move_direction.y) > 0 or abs(move_direction.z) > 0

func toggle_floating() -> void:
	if move_controller.actor_state() != ActorStateList.floating:
		move_controller.set_actor_state(ActorStateList.floating)
		motion_mode = MotionMode.MOTION_MODE_FLOATING
	else:
		move_controller.set_actor_state(ActorStateList.neutral)
		motion_mode = MotionMode.MOTION_MODE_GROUNDED

func toggle_crouching() -> void:
	if actor_state != ActorStateList.crouching and actor_state != ActorStateList.floating:
		move_controller.set_actor_state(ActorStateList.crouching)
		motion_mode = MotionMode.MOTION_MODE_GROUNDED
		if collider.shape:
			if collider.shape is CapsuleShape3D:
				var cap: CapsuleShape3D = collider.shape
				cap.height = cap.height / 2
				collider.position -= Vector3(0, cap.height / 2, 0)
				print(collider.position)
	else:
		move_controller.set_actor_state(ActorStateList.neutral)
		motion_mode = MotionMode.MOTION_MODE_GROUNDED
		if collider.shape:
			if collider.shape is CapsuleShape3D:
				var cap: CapsuleShape3D = collider.shape
				collider.position += Vector3(0, cap.height / 2, 0)
				print(collider.position)
				cap.height = cap.height * 2

func _on_health_changed(old: int, new: int):
	print("%s took damage - %s to %s" % [name, old, new])

func basic_movement(delta: float):
	if moving():
		move_controller.set_move_dir(move_direction)
		if _jumped:
			anim_controller.anim_tree["parameters/jump/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
			if is_on_floor():
				velocity += Vector3(0, 5, 0)
				if actor_state == ActorStateList.crouching:
					toggle_crouching()
		else:
			if _sprinting:
				if move_controller.actor_state() != ActorStateList.floating:
					move_controller.set_move_state(MoveStateList.sprint)
			else:
				move_controller.set_move_state(MoveStateList.run)
	else:
		move_controller.set_move_state(MoveStateList.idle)

	var target_rotation: float = atan2(move_controller.direction.x, move_controller.direction.z) - rotation.y
	mesh_root.rotation.y = lerp_angle(mesh_root.rotation.y, target_rotation, move_controller.current_move_state.rotation_speed * delta)
	if move_controller.actor_state() != ActorStateList.floating:
		#if the state's grounded we need to ignore whatever the player wants to say about Y values, sans jumping
		#hilariously, as a result of this, the 'jump' state is actually grounded
		var vel_x: float = lerp(velocity.x, move_controller.get_desired_velocity().x, move_controller.move_state().acceleration * delta)
		var vel_z: float = lerp(velocity.z, move_controller.get_desired_velocity().z, move_controller.move_state().acceleration * delta)
		var vel_y: float = velocity.y + (_gravity_force * delta)
		#where 55 is terminal velocity
		velocity = Vector3(vel_x, vel_y, vel_z)
		
	else:
		velocity = velocity.lerp(move_controller.get_desired_velocity(), move_controller.current_move_state.acceleration * delta)
	_jumped = false
	move_and_slide()

func _physics_process(delta: float):
	basic_movement(delta)
