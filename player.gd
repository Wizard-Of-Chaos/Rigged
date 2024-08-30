extends CharacterBody3D

@export var movestates: Dictionary
@onready var mesh_root: Node3D = $MeshRoot
@onready var camera_root: CameraController = $CameraRoot
@onready var anim_tree: AnimationTree = $MeshRoot/AnimationTree

var move_controller: MoveController = MoveController.new()
var anim_controller: AnimationController = AnimationController.new()
func _ready():
	move_controller.set_movestate(movestates["idle"])
	move_controller._set_player(self)
	move_controller.movestate_set.connect(camera_root._on_set_movestate)
	move_controller.movestate_set.connect(anim_controller._on_set_movestate)
	anim_controller.set_tree(anim_tree)
	
var move_direction: Vector3: 
	get:
		var dir := Vector3.ZERO
		dir.x = _left_strength - _right_strength
		dir.z = _forward_strength - _back_strength
		if(_jumped):
			dir.y = 1.0
		elif not is_on_floor():
			dir.y = -1.0
		else:
			dir.y = 0.0
		return dir
var _right_strength: float = 0.0
var _left_strength: float = 0.0
var _forward_strength: float = 0.0
var _back_strength: float = 0.0
var _sprinting: bool = false
var _jumped: bool = false

func moving() -> bool:
	return abs(move_direction.x) > 0 or abs(move_direction.y) > 0 or abs(move_direction.z) > 0

func _input(event: InputEvent):
	if event.is_action("move_forward"):
		_forward_strength = event.get_action_strength("move_forward")
	elif event.is_action("move_back"):
		_back_strength = event.get_action_strength("move_back")
	elif event.is_action("move_right"):
		_right_strength = event.get_action_strength("move_right")
	elif event.is_action("move_left"):
		_left_strength = event.get_action_strength("move_left")
	elif event.is_action("sprint"):
		_sprinting = event.is_action_pressed("sprint", true)
	elif event.is_action_pressed("jump") and is_on_floor():
		_jumped = event.is_action_pressed("jump")
	elif event.is_action_pressed("pause_menu") and event.device < -1:
		SteamInputGlobal.show_binding_panel(event.device)

func _physics_process(delta: float):
	if moving():
		move_controller.set_move_dir(move_direction)
		move_controller.set_movestate(movestates["sprint"] if _sprinting else movestates["run"])
	else:
		move_controller.set_movestate(movestates["idle"])
	var target_rotation: float = atan2(move_controller.direction.x, move_controller.direction.z) - rotation.y
	mesh_root.rotation.y = lerp_angle(mesh_root.rotation.y, target_rotation, move_controller.rotation_speed * delta)
	velocity = velocity.lerp(move_controller.get_velocity(), move_controller.acceleration * delta)
	_jumped = false
	move_and_slide()


func _on_camera_root_set_cam_rotation(p_cam_rotation: float) -> void:
	move_controller.set_rotation(p_cam_rotation)
	
