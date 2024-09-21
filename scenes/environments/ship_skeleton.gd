extends Area3D
class_name ShipSkeleton

@export var cells_wide: int = 32
@export var cells_long: int = 64
@export var cells_tall: int = 8

@export var bridge_position: Vector3 = Vector3(0,0,0)
@export var bridge_size: Vector3 = Vector3(0,0,0)

@export var engines_position: Vector3 = Vector3(0,0,0)
@export var engines_size: Vector3 = Vector3(0,0,0)

@export var oxygen_position: Vector3 = Vector3(0,0,0)
@export var airlock_positions: Dictionary
 
# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func generate():
	pass
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
