extends Control

@onready var health_bar := $TextureProgressBar  # Reference to the health bar
var player_health: Health = null

func _ready():
	# Access the local player's node and Health component
	var local_player = find_local_player()
	
	if local_player:
		player_health = local_player.get_node("Health")
		if player_health:
			# Connect to the signal to listen for health changes
			player_health.connect("health_changed", Callable(self, "_on_health_changed"))
			# Initialize the health bar with the current health
			health_bar.value = player_health.current_health
		else:
			print("Health node not found on local player.")
	else:
		print("Local player is null. Check GameState or player initialization.")

# Update the health bar when health changes
func _on_health_changed(old_health: int, new_health: int):
	health_bar.value = new_health

# Function to find the local player's node via GameState
func find_local_player() -> Node:
	# Access the GameState (autoloaded singleton)
	var local_peer_id = multiplayer.get_unique_id()
	
	for player in GameState.players:
		if player["peer_id"] == local_peer_id:
			return player["player_node"]
	
	return null  # Return null if no local player is found
