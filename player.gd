extends CharacterBody3D

signal set_movestate(_movestate : MoveState)
signal set_movedir(_movedir : Vector3)

@export var movestates : Dictionary

func _ready():
	set_movestate.emit(movestates["idle"])

var move_direction : Vector3

func moving() -> bool:
	return abs(move_direction.x) > 0 or abs(move_direction.y) > 0 or abs(move_direction.z) > 0

func _input(event):
	move_direction = Vector3.ZERO
	move_direction.x = Input.get_action_strength("move_left") - Input.get_action_strength("move_right")
	move_direction.z = Input.get_action_strength("move_forward") - Input.get_action_strength("move_back")
	if moving():
		if Input.is_action_pressed("sprint"):
			set_movestate.emit(movestates["sprint"])
		else:
			set_movestate.emit(movestates["run"])
	else:
		set_movestate.emit(movestates["idle"])
		
func _physics_process(_delta):
	if moving():
		set_movedir.emit(move_direction)
