extends Area3D
class_name ShipCell

@export_range(1, 6) var cells_x = 1
@export_range(1, 6) var cells_y = 1
@export_range(1, 6) var cells_z = 1
@onready var bounding_area: CollisionShape3D = %Box
const door_offsets: PackedVector3Array = [ # in order
	Vector3(12, 0, 16), Vector3(4, 0, 16), Vector3(-4, 0, 16), Vector3(-12, 0, 16),
	Vector3(-16, 0, 12), Vector3(-16, 0, 4), Vector3(-16, 0, -4), Vector3(-16, 0, -12),
	Vector3(-12, 0, -16), Vector3(-4, 0, -16), Vector3(4, 0, -16), Vector3(12, 0, -16),
	Vector3(16, 0, -12), Vector3(16, 0, -4), Vector3(16, 0, 4), Vector3(16, 0, 12),
]

func _ready():
	var box: BoxShape3D = bounding_area.shape
	box.size = Vector3(cells_x * 32, cells_y * 16, cells_z * 32)
	bounding_area.position = Vector3(0, box.size.y * 8, 0)

func _process(_delta):
	pass
