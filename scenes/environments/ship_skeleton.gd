extends Node3D
class_name ShipSkeleton

const MAX_ROOM_PLACEMENT_ATTEMPTS := 5
const CELL_LENGTH := 32
const CELL_WIDTH := 32
const CELL_HEIGHT := 16
const CELL_DIMENSIONS := Vector3i(CELL_LENGTH, CELL_HEIGHT, CELL_WIDTH)
@export_range(1, 32) var cells_wide := 32
@export_range(1, 64) var cells_long := 64
@export_range(1, 8) var cells_tall := 8

@export var bridge_position: Vector3i = Vector3i(0,0,0)

@export var engines_position := Vector3i(5,0,0)

@export var oxygen_position := Vector3i(0,0,3)
@export var airlock_positions: Dictionary

@export var max_rooms: int
@export var room_types: Array[PackedScene]

@export var rng_seed: int

@export var minimum_timer := 1200.0
@export var maximum_timer := 1800.0

@export var generate_on_ready := false

var _rng: RandomNumberGenerator
var _tile_map: Dictionary

func _ready():
	_rng = RandomNumberGenerator.new()
	if rng_seed == 0:
		_rng.randomize()
		rng_seed = _rng.seed
	else:
		_rng.seed = rng_seed
	if generate_on_ready:
		generate()

func _add_room(p_tile: PackedScene, p_position: Vector3i) -> int:
	if _tile_map.has(p_position):
		return ERR_ALREADY_IN_USE
	var instantiated_tile := p_tile.instantiate()
	instantiated_tile.position = p_position * CELL_DIMENSIONS
	add_child(instantiated_tile)
	_tile_map[p_position] = instantiated_tile
	return OK

func _remove_room(p_position: Vector3i) -> int:
	if not _tile_map.has(p_position):
		return ERR_DOES_NOT_EXIST
	_tile_map.erase(p_position)
	return OK

func generate():
	var bridge_tile := preload("res://scenes/environments/cells/bridge_test.tscn")
	_add_room(bridge_tile, bridge_position)
	var engine_tile := preload("res://scenes/environments/cells/engine_test.tscn")
	_add_room(engine_tile, engines_position)
	var oxygen_tile := preload("res://scenes/environments/cells/oxygen_test.tscn")
	_add_room(oxygen_tile, oxygen_position)
	
	var airlock_tile := preload("res://scenes/environments/cells/airlock_test.tscn")
	for airlock_key in airlock_positions:
		var airlock_position: Vector3i = airlock_positions[airlock_key]
		_add_room(airlock_tile, airlock_position)
	
	for i in max_rooms:
		for attempt in MAX_ROOM_PLACEMENT_ATTEMPTS:
			var room_tile := room_types[_rng.randi_range(0, room_types.size() - 1)]
			var y_coord := _rng.randi_range(0, cells_tall - 1)
			var x_coord := _rng.randi_range(0, cells_wide)
			var z_coord := _rng.randi_range(0, cells_long)
			var res := _add_room(room_tile, Vector3i(x_coord, y_coord, z_coord))
			if res == OK:
				break
