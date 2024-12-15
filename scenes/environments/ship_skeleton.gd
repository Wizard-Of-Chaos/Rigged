extends Area3D
class_name ShipSkeleton

const CELL_WIDTH := 32
const CELL_HEIGHT := 16
const CELL_LENGTH := 32

const MAX_ROOM_PLACEMENT_ATTEMPTS := 5
@export_range(1, 32) var cells_wide := 32
@export_range(1, 64) var cells_long := 64
@export_range(1, 8) var cells_tall := 8

@export var bridge_position: Vector3 = Vector3(0,0,0)

@export var engines_position := Vector3(5 * CELL_WIDTH,0,0)

@export var oxygen_position := Vector3(0,0,3 * CELL_LENGTH)
@export var airlock_positions: Dictionary

@export var max_rooms: int
@export var room_types: Array[PackedScene]

@export var rng_seed: int

@export var minimum_timer := 1200.0
@export var maximum_timer := 1800.0
@onready var bounding_area: CollisionShape3D = %ShipBox

@export var generate_on_ready := false

var _rng: RandomNumberGenerator

func _ready():
	_rng = RandomNumberGenerator.new()
	if rng_seed == 0:
		_rng.randomize()
		rng_seed = _rng.seed
	else:
		_rng.seed = rng_seed
	var box: BoxShape3D = bounding_area.shape
	box.size = Vector3(cells_wide * CELL_WIDTH, cells_tall * CELL_HEIGHT, cells_long * CELL_LENGTH)
	bounding_area.position = Vector3(0, box.size.y * 8, 0)
	if generate_on_ready:
		generate()
	
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
	
	for i in max_rooms:
		for attempt in MAX_ROOM_PLACEMENT_ATTEMPTS:
			var room_type := room_types[_rng.randi_range(0, room_types.size() - 1)]
			var potential_room: ShipCell = room_type.instantiate()
			var floor_number := _rng.randi_range(0, cells_tall - 1)
			var y_coord := floor_number * CELL_HEIGHT
			var x_coord := _rng.randf_range(0, cells_wide * CELL_WIDTH)
			var z_coord := _rng.randf_range(0, cells_long * CELL_LENGTH)
			
			var shape_query := PhysicsShapeQueryParameters3D.new()
			shape_query.collide_with_areas = true
			shape_query.collide_with_bodies = false
			shape_query.exclude.append(bounding_area.shape.get_rid())
			# TODO: fine tune the .margin of this query to have rooms have a minimum spacing
			potential_room.position = Vector3(x_coord, y_coord, z_coord)
			# TODO: make a box on the physics server to query instead of doing this
			add_child(potential_room)
			shape_query.exclude.append(potential_room.bounding_area.shape.get_rid())
			shape_query.shape_rid = potential_room.bounding_area.shape.get_rid()
			var physics_space_rid := PhysicsServer3D.area_get_space(get_rid())
			var physics_space := PhysicsServer3D.space_get_direct_state(physics_space_rid)
			var collisions := physics_space.intersect_shape(shape_query)
			
			if collisions.size() == 0:
				break
			remove_child(potential_room)
	print("hooray ship generated!")
