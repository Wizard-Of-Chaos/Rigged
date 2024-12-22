extends Node3D

@onready var players := %Players
@onready var UI := %UI
@onready var player_spawner := %PlayerSpawner

#TODO: Set up this when loading a skeleton in ready rather than straight from the start
@onready var skeleton := $ShipSkeleton

var timer: float = 0
var max_timer: float = 0
var objectives: Array
var total_score: int = 0
var _is_camera_setup: bool = false

func _on_add_score(obj: Objective):
	if obj.completed == true:
		return
	obj.completed = true
	total_score += obj.value
	max_timer += obj.time_added

func _ready() -> void:
	GameState.set_state(GameState.State.IN_GAME)
	if multiplayer.is_server():
		for player in GameState.players.filter(func(player_info): return player_info.is_active):
			print("setting up player %s" % player)
			player_spawner.spawn(player)
			#player_instance.set_up.rpc(player)
	
	#TODO: this should be set up from the loaded ship skeleton
	#so we should, like, load the ship skeleton here
	for child in skeleton.get_children():
		if child is ShipCell:
			for obj_scene in child.get_node("%Objectives").get_children():
				var obj: Objective = obj_scene.get_node("%Objective")
				objectives.push_back(obj)
				
	for obj: Objective in objectives:
		#hook up each objective to the added score
		obj.completed_objective_set.connect(_on_add_score)
	max_timer = skeleton.minimum_timer + randi_range(0, skeleton.maximum_timer - skeleton.minimum_timer)
	

@rpc("any_peer", "call_local", "reliable")
func camera_setup():
	var active_local_players := GameState.players.filter(func(player_info): return player_info.is_active and player_info.peer_id == multiplayer.get_unique_id())
	for player_idx in range(0, active_local_players.size()):
		var subviewport_container := SubViewportContainer.new()
		subviewport_container.stretch = true
		subviewport_container.anchor_right = 1.0 if player_idx % 2 == 1 or active_local_players.size() <= 2 or active_local_players.size() == 3 and player_idx == 2 else 0.5
		subviewport_container.anchor_left = 0.0 if player_idx % 2 == 0 or active_local_players.size() <= 2 else 0.5
		subviewport_container.anchor_bottom = 0.5 if player_idx < 2 and active_local_players.size() > 2 or player_idx == 0 and active_local_players.size() == 2 else 1.0
		subviewport_container.anchor_top = 0.0 if player_idx == 0 or player_idx == 1 and active_local_players.size() > 2 else 0.5
		var subviewport := SubViewport.new()
		
		subviewport_container.add_child(subviewport)
		var camera = preload("res://scenes/utilities/camera.tscn").instantiate()
		camera.name = "CameraRoot"
		camera.devices = active_local_players[player_idx].devices
		subviewport.add_child(camera)
		add_child(subviewport_container)
		var player: Player = active_local_players[player_idx].player_node
		player.remote_transform.remote_path = camera.get_path()
		camera.remote_transform.remote_path = player.ik_target.get_path()
				
		player.move_controller.move_state_set.connect(camera._on_set_move_state)
		player.move_controller.actor_state_set.connect(camera._on_set_actor_state)
		camera.set_cam_rotation.connect(player._on_camera_root_set_cam_rotation)
		player.camera_root = camera
		
		#TODO: there has to be a better way of maintaining access to the camera from the gun with possible gun swaps
		# player.pistol.camera = player.camera_root.camera
		
func _physics_process(delta):
	if not _is_camera_setup:
		camera_setup.rpc()
		_is_camera_setup = true
	timer += delta
	if timer >= max_timer:
		pass
		#TODO: determine end-game state for max timeout
