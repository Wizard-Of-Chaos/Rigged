class_name HackObjective extends Objective

var hacked: bool = false
var activated: bool = false

var time_to_hack: float = 10
var current_time_hacking: float = 0
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

#Override the is_complete bool to determine whether or not the objective was successful
func _is_complete() -> bool:
	return hacked

func _physics_process(delta: float):
	if activated and not hacked:
		current_time_hacking += delta
		if current_time_hacking >= time_to_hack:
			completed_objective.emit()
			hacked = true
			print("Hacked!")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
