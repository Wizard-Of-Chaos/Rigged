extends Control

func _ready():
	pass

func _onStart():
	get_tree().change_scene_to_file("res://basic.tscn")
	
func _onOptions():
	#you change scene to show the options menu
	#looks like:
	#var options = load("scene").instance()
	#get_tree().current_scene.add_child(options)
	pass

func _onQuit():
	get_tree().quit()
