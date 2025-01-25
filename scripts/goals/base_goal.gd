class_name Goal
extends Resource

## Determines whether or not AI should consider this goal
## when determining which goal to pursue
func is_valid() -> bool:
	return true


## The priority of the goal, used when determining which goal to pursue
func priority() -> int:
	return 1


## Desired world state in order to consider the goal "achieved", 
func get_desired_state() -> Dictionary:
	return {}
