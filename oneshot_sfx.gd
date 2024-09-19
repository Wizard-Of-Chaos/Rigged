extends Node

class_name OneshotSfx

#signal health_changed(old_health: int, new_health: int)

var _sfx: FmodEvent = null

@export var room_muffling = "close":
	set(value):
		room_muffling = value
		
@export var reverb = "medium_room":
	set(value):
		reverb=value
		

func instance_and_play(event_path, transform):
	_sfx = FmodServer.create_event_instance(event_path)
	_sfx.set_3d_attributes(transform)
	_sfx.set_parameter_by_name_with_label("room_muffling", room_muffling, true)
	_sfx.set_parameter_by_name_with_label("reverb", reverb, true)
	_sfx.set_volume(1)
	_sfx.start()
	

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
