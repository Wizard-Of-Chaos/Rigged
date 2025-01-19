@tool
extends NavigationRegion3D
class_name ShipCell

@export_range(1, 6) var cells_x := 1
@export_range(1, 6) var cells_y := 1
@export_range(1, 6) var cells_z := 1
## Which doors are in use based on the door_offsets array, make sure no more than 15 entries 
## are in this array and that no duplicates are used
@export_range(0, 15) var doors_in_use: Array[int]
@onready var bounding_area: CollisionShape3D = %Box
const door_offsets: PackedVector3Array = [ # in order
	Vector3(12, 0, 20), Vector3(4, 0, 20), Vector3(-4, 0, 20), Vector3(-12, 0, 20),
	Vector3(-20, 0, 12), Vector3(-20, 0, 4), Vector3(-20, 0, -4), Vector3(-20, 0, -12),
	Vector3(-12, 0, -20), Vector3(-4, 0, -20), Vector3(4, 0, -20), Vector3(12, 0, -20),
	Vector3(20, 0, -12), Vector3(20, 0, -4), Vector3(20, 0, 4), Vector3(20, 0, 12),
]
const door_hallway_offsets: Array[Vector3i] = [
	Vector3i(0,0,-1), Vector3i(0,0,-1), Vector3i(0,0,-1), Vector3i(0,0,-1),
	Vector3i(1,0,0), Vector3i(1,0,0), Vector3i(1,0,0), Vector3i(1,0,0),
	Vector3i(0,0,1), Vector3i(0,0,1), Vector3i(0,0,1), Vector3i(0,0,1),
	Vector3i(-1, 0, 0), Vector3i(-1, 0, 0), Vector3i(-1, 0, 0), Vector3i(-1, 0, 0)
]

func _ready():
	var box: BoxShape3D = bounding_area.shape
	box.size = Vector3(cells_x * 32, cells_y * 16, cells_z * 32)
	bounding_area.position = Vector3(0, cells_y * 8, 0)
func door_global_pos(door_idx: int) -> Vector3:
	if door_idx == -1:
		return global_position
	return global_position + door_offsets[door_idx]
