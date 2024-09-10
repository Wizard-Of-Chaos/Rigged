class_name Player
extends CharacterBody3D

@export var movestates: Dictionary
@export var playerstates: Dictionary
@onready var mesh_root: Node3D = %MeshRoot
@onready var anim_tree: AnimationTree = $MeshRoot/Guy/AnimationTree
@onready var move_controller: MoveController = %MoveController

@onready var ik_target: Marker3D = %IKTarget
@onready var remote_transform: RemoteTransform3D = %RemoteTransform

@onready var ik_arm_target: Marker3D = %ArmIKTarget
@onready var pistol: Weapon = $MeshRoot/Guy/Armature/Skeleton3D/GunAttachment/Pistol
@onready var ik_arm: SkeletonIK3D = $MeshRoot/Guy/Armature/Skeleton3D/ArmIK
@export var camera_root: CameraController
var anim_controller: AnimationController = AnimationController.new()
var devices: Array[int] = []

func _ready():
	move_controller.set_movestate(movestates["idle"])
	move_controller.set_playerstate(playerstates["neutral"])
	move_controller.movestate_set.connect(anim_controller._on_set_movestate)
	anim_controller.set_tree(anim_tree)
	pistol.visible = false

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

@rpc("any_peer", "call_local", "reliable")
func set_up(player_info: Dictionary) -> void:
	set_multiplayer_authority(player_info.peer_id)
	if player_info.peer_id == multiplayer.get_unique_id():
		player_info.player_node = self
		devices = player_info.devices
		move_controller.playerstate_set.connect(anim_controller._on_set_playerstate)
		pistol.visible = false
		ik_arm.stop() 


func _input(event: InputEvent):
	if not is_multiplayer_authority() or not event.device in devices:
		return
	pistol.firing = false
	if event is InputEventMouseMotion:
		camera_root.cam_input(event)
	elif event.is_action("move_forward"):
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
	elif event.is_action_pressed("equip_weapon"):
		if move_controller.current_player_state.name == "neutral" or move_controller.current_player_state.name == "weapon_aiming":
			move_controller.set_playerstate(playerstates["weapon_equipped"])
			pistol.visible = true
		else:
			move_controller.set_playerstate(playerstates["neutral"])
			pistol.visible = false
	elif event.is_action_pressed("aim"):
		if pistol.visible:
			if move_controller.current_player_state.name == "weapon_equipped":
				move_controller.set_playerstate(playerstates["weapon_aiming"])
				ik_arm.start()
			else:
				move_controller.set_playerstate(playerstates["weapon_equipped"])
				ik_arm.stop()
				
	if event.is_action_pressed("fire") and move_controller.current_player_state.name == "weapon_aiming":
		pistol.firing = true
	else:
		pistol.firing = false
	
	if event.is_action_pressed("interact"):
		pass

func _physics_process(delta: float):
	if moving():
		move_controller.set_move_dir(move_direction)
		move_controller.set_movestate(movestates["sprint"] if _sprinting else movestates["run"])
	else:
		move_controller.set_movestate(movestates["idle"])
	var target_rotation: float = atan2(move_controller.direction.x, move_controller.direction.z) - rotation.y
	mesh_root.rotation.y = lerp_angle(mesh_root.rotation.y, target_rotation, move_controller.rotation_speed * delta)
	velocity = velocity.lerp(move_controller.get_velocity(is_on_floor()), move_controller.acceleration * delta)
	_jumped = false
	move_and_slide()


func _on_camera_root_set_cam_rotation(p_cam_rotation: float) -> void:
	move_controller.set_rotation(p_cam_rotation)
	
