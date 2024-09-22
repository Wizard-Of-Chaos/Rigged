extends Control

@onready var health_bar := $TextureProgress # Reference to the health bar
var player_health: Health = null

func _ready():
	# Find the player node and get the Health component (assuming the player is in the same scene tree)
	var player = get_tree().get_root().get_node("Path/To/Player")
	if player:
		player_health = player.get_node("Health")
		# Connect to the signal to listen for health changes
		player_health.connect("health_changed", Callable(self, "_on_health_changed"))
		# Initialize the health bar to full
		health_bar.value = player_health.current_health

func _on_health_changed(old_health: int, new_health: int):
	health_bar.value = new_health
