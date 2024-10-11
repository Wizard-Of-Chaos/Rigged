extends Area3D
class_name ShipSkeleton

@export_range(1, 32) var cells_wide: int = 32
@export_range(1, 64) var cells_long: int = 64
@export_range(1, 8) var cells_tall: int = 8

@export var bridge_position: Vector3 = Vector3(0,0,0)
@export var bridge_size: Vector3 = Vector3(0,0,0)

@export var engines_position: Vector3 = Vector3(0,0,0)
@export var engines_size: Vector3 = Vector3(0,0,0)

@export var oxygen_position: Vector3 = Vector3(0,0,0)
@export var airlock_positions: Dictionary

@export var minimum_timer: float = 1200.0
@export var maximum_timer: float = 1800.0
@onready var bounding_area: CollisionShape3D = %ShipBox

func _ready():
	var box: BoxShape3D = bounding_area.shape
	box.size = Vector3(cells_wide * 32, cells_tall * 16, cells_long * 32)
	bounding_area.position = Vector3(0, box.size.y * 8, 0)
	
func generate():
	pass
	
func _process(_delta):
	pass
