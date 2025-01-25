class_name AIController
extends Node

@export var actions: Array[BaseAction]
@export var goals: Array[Goal]


func get_plan(goal: Goal, blackboard: Dictionary = {}) -> Array[BaseAction]:
	var desired_state = goal.get_desired_state().duplicate()
	if desired_state.is_empty():
		return []
	return _find_best_plan(goal, desired_state, blackboard)
	
func _find_best_plan(goal: Goal, desired_state: Dictionary, blackboard: Dictionary) -> Array[BaseAction]:
	var root := {
		"action": goal,
		"state": desired_state,
		"children": []
	}
	if _build_plans(root, blackboard.duplicate()):
		var plans = _transform_tree_into_array(root, blackboard)
		return _get_cheapest_plan(plans)
	return []

func _get_cheapest_plan(plans: Array) -> Array[BaseAction]:
	var best_plan
	for p in plans:
		if best_plan == null or p.cost < best_plan.cost:
			best_plan = p
	return best_plan.actions


func _build_plans(step: Dictionary, blackboard: Dictionary) -> bool:
	var has_followup := false
	
	var state: Dictionary = step.state.duplicate()
	for s in step.state:
		# if the blackboard (i.e. the current state) contains the step's desired state
		# then we've achieved that piece of the state and can erase it from consideration
		if state[s] == blackboard.get(s):
			state.erase(s)
	# if the state is empty then that means we've achieved the goal with this sequence of actions!
	if state.is_empty():
		return true
	for action in actions:
		if not action.is_valid():
			continue
		var should_use_action = false
		var effects := action.get_effects()
		var desired_state := state.duplicate()
		for s in desired_state:
			# if at least one of this action's effects is a desired_state then we should use it
			if desired_state[s] == effects.get(s):
				desired_state.erase(s)
				should_use_action = true
		
		if should_use_action:
			var preconditions := action.get_preconditions()
			# we now need to add this action's preconditions to the desired state
			for p in preconditions:
				desired_state[p] = preconditions[p]
			var next_step := {
				"action": action,
				"state": desired_state,
				"children": []
			}
			# if the desired state is empty then this action can be included in the graph
			# if it's non-empty then we can recursively call build_plans to see if there's another action we can take
			if desired_state.is_empty() or _build_plans(next_step, blackboard.duplicate()):
				step.children.push_back(next_step)
				has_followup = true
	return has_followup


func _transform_tree_into_array(p: Dictionary, blackboard: Dictionary) -> Array:
	var plans := []
	if p.children.size() == 0:
		var plan_actions: Array[BaseAction] = [p.action]
		plans.push_back({ "actions": plan_actions, "cost": p.action.get_cost(blackboard)})
		return plans
	
	for c in p.children:
		for child_plan in _transform_tree_into_array(c, blackboard):
			if p.action.has_method("get_cost"):
				child_plan.actions.push_back(p.action)
				child_plan.cost += p.action.get_cost(blackboard)
			plans.push_back(child_plan)
	return plans
