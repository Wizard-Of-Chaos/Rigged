class_name BaseAction
extends Resource

## Whether or not this action is valid to perform, will cause a plan to abort if action becomes invalid
## in the middle of execution
func is_valid() -> bool:
	return true


## Cost of the action, total cost of a plan is sum of all action costs
func get_cost(_blackboard: Dictionary) -> int:
	return 1000


## World state requirements to perform the action
func get_preconditions() -> Dictionary:
	return {}


## Resulting world state after performing this action
func get_effects() -> Dictionary:
	return {}


## Actual logic to perform the action, returns true if the action is completed
func perform(_actor: BaseActor, _delta: float) -> bool:
	return false
