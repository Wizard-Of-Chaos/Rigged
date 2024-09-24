extends Area3D
class_name ShipCell

@export var cells_x = 1
@export var cells_y = 1
@export var cells_z = 1
# Called when the node enters the scene tree for the first time.
func _ready():
	
	var collision_shape: CollisionShape3D = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(cells_x * 32, cells_y * 16, cells_z * 32)
	collision_shape.position = Vector3(0, box.size.y * 8, 0)
	collision_shape.shape = box
	self.add_child(collision_shape)
	
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
