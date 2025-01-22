extends BaseActor
class_name Player

@onready var ik_target: Marker3D = %IKTarget
@onready var ik_arm_target: Marker3D = %ArmIKTarget
@onready var ik_arm: SkeletonIK3D = $MeshRoot/Armature/Skeleton3D/ArmIK

# @onready var pistol: Weapon = $MeshRoot/Guy/Armature/Skeleton3D/GunAttachment/Pistol
@export var camera_root: CameraController

var wep_visible: bool = false
var devices: Array[int] = []

func _ready():
	anim_tree = $MeshRoot/AnimationTree
	move_controller.set_move_state(MoveStateList.idle)
	move_controller.set_actor_state(ActorStateList.neutral)
	move_controller.move_state_set.connect(anim_controller._on_set_move_state)
	anim_controller.set_tree(anim_tree)
	# pistol.visible = false
	if get_multiplayer_authority() == multiplayer.get_unique_id():
		var player_info
		for player in GameState.players:
			# TODO: kinda hacky, find a better way
			if player.peer_id == multiplayer.get_unique_id() and player.player_node == null:
				player_info = player
				break
		player_info.player_node = self
		devices = player_info.devices
		move_controller.actor_state_set.connect(anim_controller._on_set_actor_state)
		# pistol.visible = false
		ik_arm.stop()

@rpc("any_peer", "call_local", "reliable")
func set_up(player_info: Dictionary) -> void:
	print("setting up a player!")
	if player_info.peer_id == multiplayer.get_unique_id():
		player_info.player_node = self
		devices = player_info.devices
		move_controller.player_state_set.connect(anim_controller._on_set_actor_state)
		wep_visible = false
		ik_arm.stop()

func _input(event: InputEvent):
	if not is_multiplayer_authority() or not event.device in devices:
		return
	# pistol.firing = false
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
	elif event.is_action_pressed("jump") and is_on_floor() and actor_state != ActorStateList.floating:
		_jumped = event.is_action_pressed("jump")
	elif event.is_action("jump") and actor_state == ActorStateList.floating:
		_up_strength = event.get_action_strength("jump")
	elif event.is_action("descend") and actor_state == ActorStateList.floating:
		_down_strength = event.get_action_strength("descend")
	elif event.is_action_pressed("pause_menu") and event.device < -1:
		SteamInputGlobal.show_binding_panel(event.device)
	elif event.is_action_pressed("roll"):
		toggle_crouching()
	
	if event.is_action_pressed("interact"):
		camera_root.aim_ray.force_raycast_update()
		if camera_root.aim_ray.is_colliding():
			var collider: Node3D = camera_root.aim_ray.get_collider()
			if collider.has_node("%Interactable"):
				var interact: Interactable = collider.get_node("%Interactable")
				interact._interact(self)
				print("I can interact with this thing!")
			else:
				print("I hit something, but can't interact with it")
		else:
			print("Nothing to hit or interact with")
	
	if event.is_action_pressed("debug_float_toggle"):
		toggle_floating()
	if event.is_action_pressed("take_damage"):
		health_node.damage(50)  # Call the take_damage function, reduce 50 HP for testing

func _physics_process(delta: float):
	basic_movement(delta)
	move_and_slide()

func _on_camera_root_set_cam_rotation(p_cam_rotation: float) -> void:
	move_controller.set_rotation(p_cam_rotation)
