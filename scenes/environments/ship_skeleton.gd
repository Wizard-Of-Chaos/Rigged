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
 
func _ready():
	var collision_shape: CollisionShape3D = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(cells_wide * 32, cells_tall * 16, cells_long * 32)
	collision_shape.position = Vector3(0, box.size.y * 8, 0)
	collision_shape.shape = box
	self.add_child(collision_shape)
	
func generate():
	pass
	
func _process(delta):
	pass
