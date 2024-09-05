extends Node3D

@onready var players := %Players
@onready var UI := %UI

func _ready() -> void:
	GameState.set_state(GameState.State.IN_GAME)
	if multiplayer.is_server():
		var player_scene := preload("res://player.tscn")
		print(GameState.players)
		print(GameState.players.filter(func(player_info): return player_info.is_active))
		for player in GameState.players.filter(func(player_info): return player_info.is_active):
			print("setting up player %s" % player)
			var player_instance := player_scene.instantiate()
			player_instance.name = "Player%s" % player.peer_id
			player_instance.position.x = randi_range(-60, 60)
			player_instance.position.z = randi_range(-60, 60)
			player_instance.position.y = 10
			players.add_child(player_instance, true)
			player_instance.set_up.rpc(player)
		camera_setup.rpc()


@rpc("any_peer", "call_local", "reliable")
func camera_setup():
	var active_local_players := GameState.players.filter(func(player_info): return player_info.is_active and player_info.peer_id == multiplayer.get_unique_id())
	print("active local players: %s" % [active_local_players])
	for player_idx in range(0, active_local_players.size()):
		var subviewport_container := SubViewportContainer.new()
		subviewport_container.stretch = true
		subviewport_container.anchor_right = 1.0 if player_idx % 2 == 1 or active_local_players.size() <= 2 or active_local_players.size() == 3 and player_idx == 2 else 0.5
		subviewport_container.anchor_left = 0.0 if player_idx % 2 == 0 or active_local_players.size() <= 2 else 0.5
		subviewport_container.anchor_bottom = 0.5 if player_idx < 2 and active_local_players.size() > 2 or player_idx == 0 and active_local_players.size() == 2 else 1.0
		subviewport_container.anchor_top = 0.0 if player_idx == 0 or player_idx == 1 and active_local_players.size() > 2 else 0.5
		var subviewport := SubViewport.new()
		
		subviewport_container.add_child(subviewport)
		var camera = preload("res://camera.tscn").instantiate()
		camera.name = "CameraRoot"
		camera.devices = active_local_players[player_idx].devices
		subviewport.add_child(camera)
		add_child(subviewport_container)
		var player: Player = active_local_players[player_idx].player_node
		player.remote_transform.remote_path = camera.get_path()
		camera.remote_transform.remote_path = player.ik_target.get_path()
		player.move_controller.movestate_set.connect(camera._on_set_movestate)
		camera.set_cam_rotation.connect(player._on_camera_root_set_cam_rotation)
		player.camera_root = camera
