extends Node

func _ready() -> void:
	change_to_scene(preload("res://scenes/menus/menu.tscn"))

func change_to_scene(scene: PackedScene) -> void:
	if (!multiplayer.is_server()):
		printerr("Client (%s) trying to change scene" % multiplayer.get_unique_id())
		return
	var current_scene = %CurrentScene
	for c in current_scene.get_children():
		current_scene.remove_child(c)
		c.queue_free()
	current_scene.add_child(scene.instantiate())
