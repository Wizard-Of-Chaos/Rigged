extends Node3D

@onready var players := $Players

func _ready() -> void:
	var player := preload("res://player.tscn").instantiate()
	var camera := preload("res://camera.tscn").instantiate()
	camera.name = "CameraRoot"
	player.add_child(camera)
	player.camera_root = camera
	# TODO: centralize all spawning on the host
	player.position.x = randi_range(-60, 60)
	player.position.z = randi_range(-60, 60)
	player.position.y = 10
	players.add_child(player, true)
