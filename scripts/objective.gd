extends Node

#Signal to something else that the objective is done
signal completed_objective()

@export var min_value: int = 30
@export var max_value: int = 60

var value: int

func _ready():
	pass

#Override the is_complete bool to determine whether or not the objective was successful
func _is_complete() -> bool:
	return false

func _process(delta):
	pass
