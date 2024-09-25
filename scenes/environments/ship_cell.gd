extends Area3D
class_name ShipCell

@export_range(1, 6) var cells_x = 1
@export_range(1, 6) var cells_y = 1
@export_range(1, 6) var cells_z = 1

func _ready():
	
	var collision_shape: CollisionShape3D = CollisionShape3D.new()
	var box = BoxShape3D.new()
	box.size = Vector3(cells_x * 32, cells_y * 16, cells_z * 32)
	collision_shape.position = Vector3(0, box.size.y * 8, 0)
	collision_shape.shape = box
	self.add_child(collision_shape)

func _process(delta):
	pass
