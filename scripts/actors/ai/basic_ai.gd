extends BaseActor
class_name BasicAI

@export var ai_states: Dictionary
@export var current_ai_state: AIState
var _pursuit_target: CharacterBody3D

func _ready():
	anim_tree = $MeshRoot/AnimationTree

func _on_body_entered(body: Node3D):
	print("Player...?")
	if body.has_node("Health"):
		print("Player!!!!!!!")
		current_ai_state = ai_states["pursuit"]
		_pursuit_target = body
		
func _on_body_exited(body: Node3D):
	if body.has_node("Health"):
		current_ai_state = ai_states["idle"]
		_pursuit_target = null

func ai_state_update(delta: float):
	var move_dir = move_direction
	if current_ai_state.name == "pursuit":
		_forward_strength = 1.0
		move_dir = _pursuit_target.global_position - global_position
		if move_dir.length() < 6.0:
			_forward_strength = 0
		move_dir = move_dir.normalized()
		move_dir.y = 0
	else:
		_forward_strength = 0.0

func _physics_process(delta: float):
	
	if get_multiplayer_authority() == multiplayer.get_unique_id():
		ai_state_update(delta)
	basic_movement(delta)
	move_and_slide()
