extends MultiplayerSpawner


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.spawn_function = spawn_player

func spawn_player(data: Dictionary) -> Node:
	var player_scene = preload("res://scenes/actors/player.tscn")
	var player_instance = player_scene.instantiate()
	player_instance.name = "Player%s" % data.peer_id
	player_instance.position.x = randi_range(-10, 10)
	player_instance.position.z = randi_range(106, 118)
	player_instance.position.y = 10
	player_instance.set_multiplayer_authority(data.peer_id)
	return player_instance
