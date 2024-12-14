extends Area3D
class_name ShipSkeleton

@export_range(1, 32) var cells_wide := 32
@export_range(1, 64) var cells_long := 64
@export_range(1, 8) var cells_tall := 8

@export var bridge_position: Vector3 = Vector3(0,0,0)
@export var bridge_size := Vector3(0,0,0)

@export var engines_position := Vector3(0,0,0)
@export var engines_size := Vector3(0,0,0)

@export var oxygen_position := Vector3(0,0,0)
@export var airlock_positions: Dictionary

@export var minimum_timer := 1200.0
@export var maximum_timer := 1800.0
@onready var bounding_area: CollisionShape3D = %ShipBox

func _ready():
	var box: BoxShape3D = bounding_area.shape
	box.size = Vector3(cells_wide * 32, cells_tall * 16, cells_long * 32)
	bounding_area.position = Vector3(0, box.size.y * 8, 0)
	
func generate():
	var bridge_scene := preload("res://scenes/environments/cells/bridge_test.tscn")
	var engine_scene := preload("res://scenes/environments/cells/engine_test.tscn")
	var oxygen_scene := preload("res://scenes/environments/cells/oxygen_test.tscn")
	var airlock_scene := preload("res://scenes/environments/cells/airlock_test.tscn")
	
	var bridge := bridge_scene.instantiate()
	bridge.position = bridge_position
	add_child(bridge)
	
	var engine := engine_scene.instantiate()
	engine.position = engines_position
	add_child(engine)
	
	var oxygen := oxygen_scene.instantiate()
	oxygen.position = oxygen_position
	add_child(oxygen)
	
	for airlock_key in airlock_positions:
		var airlock_position: Vector3 = airlock_positions[airlock_key]
		var airlock := airlock_scene.instantiate()
		airlock.position = airlock_position
		add_child(airlock)
	# use PhysicsDirectSpaceState3D to query the physics space before placing randomized rooms
func _process(_delta):
	pass
