extends CharacterBody3D

@export var movestates: Dictionary
@onready var mesh_root: Node3D = $MeshRoot
@onready var camera_root: CameraController = $CameraRoot
var move_controller: MoveController = MoveController.new()

func _ready():
	move_controller.set_movestate(movestates["idle"])
	move_controller.movestate_set.connect(camera_root._on_set_movestate)

var move_direction: Vector3: 
	get:
		var dir = Vector3.ZERO
		dir.x = _left_strength - _right_strength
		dir.z = _forward_strength - _back_strength
		return dir
var _right_strength: float = 0.0
var _left_strength: float = 0.0
var _forward_strength: float = 0.0
var _back_strength: float = 0.0
var _sprinting: bool = false

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
		_sprinting = event.is_action_pressed("sprint")
	elif event.is_action_pressed("pause_menu"):
		SteamInputGlobal.show_binding_panel(event.device)

func _physics_process(delta):
	if moving():
		move_controller.set_move_dir(move_direction)
		move_controller.set_movestate(movestates["sprint"] if _sprinting else movestates["run"])
	else:
		move_controller.set_movestate(movestates["idle"])
	var target_rotation = atan2(move_controller.direction.x, move_controller.direction.z) - rotation.y
	mesh_root.rotation.y = lerp_angle(mesh_root.rotation.y, target_rotation, move_controller.rotation_speed * delta)
	velocity = velocity.lerp(move_controller.get_velocity(), move_controller.acceleration * delta)
	move_and_slide()


func _on_camera_root_set_cam_rotation(p_cam_rotation: float) -> void:
	move_controller.set_rotation(p_cam_rotation)
