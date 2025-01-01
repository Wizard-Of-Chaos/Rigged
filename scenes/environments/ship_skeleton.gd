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
var cell_at_infinity: Vector3i

class ShipAStar3D extends AStar3D:
	func _compute_cost(from_id: int, to_id: int) -> float:
		var from := get_point_position(from_id)
		var to := get_point_position(to_id)
		
		var dist := (to - from).abs()
		
		return dist.x + dist.y + dist.z
		
	func _estimate_cost(from_id: int, to_id: int) -> float:
		var from := get_point_position(from_id)
		var to := get_point_position(to_id)
		
		var dist := (to - from).abs()
		
		return dist.x + dist.y + dist.z

func _ready():
	cell_at_infinity = Vector3i(cells_long + 1, cells_tall + 1, cells_wide + 1)
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
			var x_coord := _rng.randi_range(0, cells_wide - 1)
			var z_coord := _rng.randi_range(0, cells_long - 1)
			var add_room_err := _add_room(room_tile, Vector3i(x_coord, y_coord, z_coord))
			if add_room_err == OK:
				break
	var costs := {}
	var res := {}
	var unused_verts := _tile_map.keys()
	for key in _tile_map:
		costs[key] = INF
		res[key] = cell_at_infinity

	while unused_verts.size() > 0:
		# find min cost vert
		var min_vert: Vector3i = unused_verts[0]
		for vert in unused_verts:
			if costs[vert] < costs[min_vert]:
				min_vert = vert
		unused_verts.erase(min_vert)
		for vert in unused_verts:
			var dist: Vector3i = (min_vert - vert).abs()
			var cost := dist.x + dist.y + dist.z
			if cost < costs[vert]:
				costs[vert] = cost
				res[vert] = min_vert
	var astar := ShipAStar3D.new()
	astar.reserve_space(64 * cells_long * cells_tall * cells_wide)
	var id := 0
	for x in 4 * cells_wide:
		for y in 4 * cells_tall:
			for z in 4 * cells_long:
				var pos := Vector3i(x, y, z) * (CELL_DIMENSIONS / 4)
				astar.add_point(id, pos)
				id += 1
	id = 0
	for x in 4 * cells_wide:
		for y in 4 * cells_tall:
			for z in 4 * cells_long:
				if z != 4 * cells_long - 1:
					astar.connect_points(id, id+1)
				if y != 4 * cells_tall - 1:
					astar.connect_points(id, id + 4 * cells_long)
				if x != 4 * cells_wide - 1:
					astar.connect_points(id, id + 16 * cells_tall * cells_long)
				id += 1
	var hallway_graph := {}
	for vert in res:
		if res[vert] == cell_at_infinity:
			print("not connecting root %s to %s" % [vert, res[vert]])
			continue
		#print("vert %s points to vert %s" % [vert, res[vert]])
		var from := astar.get_closest_point(vert * CELL_DIMENSIONS)
		var to := astar.get_closest_point(res[vert] * CELL_DIMENSIONS)
		var point_path := astar.get_point_path(from, to)
		#print(point_path)
		for i in point_path.size()-1:
			var hallway_from := Vector3i(point_path[i] * 4) / CELL_DIMENSIONS
			if not hallway_graph.has(hallway_from):
				hallway_graph[hallway_from] = []
			var hallway_to := Vector3i(point_path[i+1] * 4) / CELL_DIMENSIONS
			if not hallway_graph.has(hallway_to):
				hallway_graph[hallway_to] = []
			if not hallway_to in hallway_graph[hallway_from]:
				hallway_graph[hallway_from].append(hallway_to)
			if not hallway_from in hallway_graph[hallway_to]:
				hallway_graph[hallway_to].append(hallway_from)
			_draw_line(point_path[i], point_path[i+1])
	
	print(hallway_graph)
	var hallway_i_scene := preload('res://scenes/environments/corridor_legos/hall_i.tscn')
	var hallway_l_scene := preload('res://scenes/environments/corridor_legos/hall_l.tscn')
	var hallway_cap_scene := preload('res://scenes/environments/corridor_legos/hall_cap.tscn')
	var hallway_y_scene := preload('res://scenes/environments/corridor_legos/hall_y.tscn')
	var hallway_x_scene := preload('res://scenes/environments/corridor_legos/hall_x.tscn')
	for hallway_vertex in hallway_graph:
		var hallway: Node3D = null
		match hallway_graph[hallway_vertex].size():
			1:
				hallway = hallway_cap_scene.instantiate()
				var cap_dir: Vector3i = hallway_vertex - hallway_graph[hallway_vertex][0]
				hallway.look_at_from_position(Vector3(0,0,0), cap_dir)
			2:
				var first_dir: Vector3i = hallway_vertex - hallway_graph[hallway_vertex][0]
				var second_dir: Vector3i = hallway_vertex - hallway_graph[hallway_vertex][1]
				if Vector3(first_dir).dot(Vector3(second_dir)):
					hallway = hallway_i_scene.instantiate()
					hallway.look_at_from_position(Vector3(0,0,0), first_dir)
				else:
					hallway = hallway_l_scene.instantiate()
					if Vector3(first_dir).cross(second_dir) > Vector3(0,0,0):
						hallway.look_at_from_position(Vector3(0,0,0), second_dir)
					else:
						hallway.look_at_from_position(Vector3(0,0,0), first_dir)
					
			3:
				hallway = hallway_y_scene.instantiate()
				var first_dir: Vector3i = hallway_vertex - hallway_graph[hallway_vertex][0]
				var second_dir: Vector3i = hallway_vertex - hallway_graph[hallway_vertex][1]
				var third_dir: Vector3i = hallway_vertex - hallway_graph[hallway_vertex][2]
				var perpindicular_dir: Vector3i
				if Vector3(first_dir).dot(second_dir):
					perpindicular_dir = third_dir
				elif Vector3(first_dir).dot(third_dir):
					perpindicular_dir = second_dir
				else:
					perpindicular_dir = first_dir
				hallway.look_at_from_position(Vector3(0,0,0), perpindicular_dir)
			4:
				hallway = hallway_x_scene.instantiate()
			_:
				print('too many vertices')
		if hallway:
			hallway.position = hallway_vertex * (CELL_DIMENSIONS / 4)
			add_child(hallway)
func _draw_line(start_coords: Vector3, end_coords: Vector3, color := Color.RED):
		var mesh_instance := MeshInstance3D.new()
		var immediate_mesh := ImmediateMesh.new()
		var material := ORMMaterial3D.new()

		mesh_instance.mesh = immediate_mesh
		mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

		immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
		immediate_mesh.surface_add_vertex(start_coords)
		immediate_mesh.surface_add_vertex(end_coords)
		immediate_mesh.surface_end()

		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_color = color
		add_child(mesh_instance)
		return mesh_instance
