class_name Objective 
extends Node

#Signal to something else that the objective is done
signal completed_objective_set(obj: Objective)

@export var min_value: int = 30
@export var max_value: int = 60

@export var min_time_added: int = 0
@export var max_time_added: int = 0

var value: int
var time_added: int = 0
var completed: bool = false

func _ready():
	value = RandomNumberGenerator.new().randi_range(min_value, max_value)
	time_added = RandomNumberGenerator.new().randi_range(min_time_added, max_time_added)
	pass

#Override the is_complete bool to determine whether or not the objective was successful
func _is_complete() -> bool:
	return false

func _process(_delta):
	pass
