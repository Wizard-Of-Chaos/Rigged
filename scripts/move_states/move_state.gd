extends Resource
class_name MoveState

#ID
@export var id: int
#Movement speed
@export var speed: float
#Acceleration speed
@export var acceleration: float = 6
#Turn speed
@export var rotation_speed: float = 8
#Camera FOV
@export var fov: float = 80
#Animation speed
@export var animation_speed: float = 1
#Is this state on the ground
@export var grounded: bool = true
#Is this state controllable at all; i.e. knockdown
@export var controllable: bool = true
