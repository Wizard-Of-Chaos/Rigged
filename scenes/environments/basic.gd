extends Node3D

@onready var players := %Players
@onready var UI := %UI

#TODO: Set up this when loading a skeleton in ready rather than straight from the start
@onready var skeleton := $ShipSkeleton

var timer: float = 0
var max_timer: float = 0
var objectives: Array
var total_score: int = 0

func _on_add_score(obj: Objective):
	if obj.completed == true:
		return
	obj.completed = true
	total_score += obj.value
	max_timer += obj.time_added

func _ready() -> void:
	GameState.set_state(GameState.State.IN_GAME)
	if multiplayer.is_server():
		var player_scene := preload("res://scenes/actors/player.tscn")
		for player in GameState.players.filter(func(player_info): return player_info.is_active):
			print("setting up player %s" % player)
			var player_instance := player_scene.instantiate()
			players.add_child(player_instance, true)
			player_instance.name = "Player%s" % player.peer_id
			player_instance.position.x = randi_range(-20, 20)
			player_instance.position.z = randi_range(106, 118)
			player_instance.position.y = 10
			player_instance.set_up.rpc(player)
		camera_setup.rpc()
	
	#TODO: this should be set up from the loaded ship skeleton
	#so we should, like, load the ship skeleton here
	for child in skeleton.get_children():
		if child is ShipCell:
			for obj in child.get_node("%Objectives").get_children():
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
		player.move_controller.player_state_set.connect(camera._on_set_player_state)
		camera.set_cam_rotation.connect(player._on_camera_root_set_cam_rotation)
		player.camera_root = camera
		
		#TODO: there has to be a better way of maintaining access to the camera from the gun with possible gun swaps
		player.pistol.camera = player.camera_root.camera
		
func _physics_process(delta):
	timer += delta
	if timer >= max_timer:
		pass
		#TODO: determine end-game state for max timeout
