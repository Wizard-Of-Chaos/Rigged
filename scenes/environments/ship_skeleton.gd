extends GridMap
class_name ShipSkeleton

const MAX_ROOM_PLACEMENT_ATTEMPTS := 5

@export_range(1, 32) var cells_wide := 32
@export_range(1, 64) var cells_long := 64
@export_range(1, 8) var cells_tall := 8

@export var bridge_position: Vector3i = Vector3i(0,0,0)

@export var engines_position := Vector3i(5,0,0)

@export var oxygen_position := Vector3i(0,0,3)
@export var airlock_positions: Dictionary

@export var max_rooms: int
@export var room_types: Array[String]

@export var rng_seed: int

@export var minimum_timer := 1200.0
@export var maximum_timer := 1800.0

@export var generate_on_ready := false

var _rng: RandomNumberGenerator

func _ready():
	_rng = RandomNumberGenerator.new()
	if rng_seed == 0:
		_rng.randomize()
		rng_seed = _rng.seed
	else:
		_rng.seed = rng_seed
	if generate_on_ready:
		generate()
	
func generate():
	var bridge_tile := mesh_library.find_item_by_name("bridge")
	var engine_tile := mesh_library.find_item_by_name("engine")
	var oxygen_tile := mesh_library.find_item_by_name("oxygen")
	var airlock_tile := mesh_library.find_item_by_name("airlock")
	
	set_cell_item(bridge_position, bridge_tile)
	set_cell_item(engines_position, engine_tile)
	set_cell_item(oxygen_position, oxygen_tile)
	
	for airlock_key in airlock_positions:
		var airlock_position: Vector3i = airlock_positions[airlock_key]
		set_cell_item(airlock_position, airlock_tile)
	
	for i in max_rooms:
		for attempt in MAX_ROOM_PLACEMENT_ATTEMPTS:
			var room_type := room_types[_rng.randi_range(0, room_types.size() - 1)]
			var room_tile := mesh_library.find_item_by_name(room_type)
			var y_coord := _rng.randi_range(0, cells_tall - 1)
			var x_coord := _rng.randi_range(0, cells_wide)
			var z_coord := _rng.randi_range(0, cells_long)
			if get_cell_item(Vector3i(x_coord, y_coord, z_coord)) == INVALID_CELL_ITEM:
				set_cell_item(Vector3i(x_coord, y_coord, z_coord), room_tile)
