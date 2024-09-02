extends Control

func _ready():
	pass

func _on_start_pressed():
	get_tree().change_scene_to_file("res://basic.tscn")
	
func _on_options_pressed():
	grab_focus()
	#you change scene to show the options menu
	#looks like:
	#var options = load("scene").instance()
	#get_tree().current_scene.add_child(options)
	pass

func _on_quit_pressed():
	get_tree().quit()

func _on_multiplayer_pressed():
	get_tree().change_scene_to_file("res://multiplayer.tscn")
