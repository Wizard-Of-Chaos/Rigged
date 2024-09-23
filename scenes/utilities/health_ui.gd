extends Control

@onready var health_bar := $HealthBar/TextureProgressBar
@onready var lazy_health_bar := $LazyHealthBar/TextureProgressBar

var player_health: Health = null
var lazy_health: float = 500
var initial_health_difference: float = 1.0
var steps: float = 1.0


# Time it takes for the lazy health to catch up to the real health
@export var delay_speed: float = 0.05

func _ready():
	# Access GameState directly to find the local player
	var local_player = find_local_player()
	
	if local_player:
		player_health = local_player.get_node("Health")
		if player_health:
			player_health.connect("health_changed", Callable(self, "_on_health_changed"))
			health_bar.value = player_health.current_health
			lazy_health_bar.value = player_health.current_health
		else:
			print("Health node not found on local player")
	else:
		print("Local player is null, check GameState or player initialization")

# This function is called when the player's health changes
func _on_health_changed(old_health: int, new_health: int):
	health_bar.value = new_health

	lazy_health = lazy_health_bar.value
	var initial_health_difference = lazy_health - new_health
	var health_difference = lazy_health - new_health
	
	if initial_health_difference < 1.0:
		initial_health_difference = 1.0

	if health_difference > 0:
		# Call the lazy bar update and trap it here till it matches
		var steps: float = 1.0
		get_tree().create_timer(delay_speed).timeout.connect(self._update_lazy_health.bind(new_health))
	else:
		lazy_health_bar.value = new_health

# Function to handle updating the lazy health bar
func _update_lazy_health(new_health: int):
	var max_step_size: float = 6.0
	var min_step_size: float = 1.0
	var acceleration: float = 0.1

	var health_difference: float = abs(lazy_health - new_health)
	var step_size: float = min_step_size + initial_health_difference * (acceleration * steps)
	steps += 1
	step_size = clamp(step_size, min_step_size, max_step_size)

	if lazy_health > new_health:
		lazy_health -= step_size
		if lazy_health < new_health:
			lazy_health = new_health
	elif lazy_health < new_health:
		lazy_health = new_health

	lazy_health_bar.value = int(lazy_health)

	if lazy_health != new_health:
		get_tree().create_timer(delay_speed).timeout.connect(self._update_lazy_health.bind(new_health))
	else:
		lazy_health_bar.value = new_health
		lazy_health = new_health

# Function to find the local player's node via GameState
func find_local_player() -> Node:
	var local_peer_id = multiplayer.get_unique_id()
	
	for player in GameState.players:
		if player["peer_id"] == local_peer_id:
			print("Local player found: ", player["player_node"])
			return player["player_node"]
	
	print("Local player not found")
	return null
