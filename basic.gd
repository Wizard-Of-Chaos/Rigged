extends Node3D

@onready var players := $Players


func _ready() -> void:
	if multiplayer.is_server():
		var player_scene := preload("res://player.tscn")
		print(SteamLobbyGlobal.players)
		for peer_id in SteamLobbyGlobal.players:
			print("Setting up peer %s" % peer_id)
			print("PEER ID: %s" % peer_id)
			var player := player_scene.instantiate()
			player.name = "Player%s" % SteamLobbyGlobal.players[peer_id]
			player.position.x = randi_range(-60, 60)
			player.position.z = randi_range(-60, 60)
			player.position.y = 10
			players.add_child(player, true)
			player.set_up.rpc(peer_id)
			
		
