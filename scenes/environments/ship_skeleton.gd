@tool
extends Node3D
class_name ShipSkeleton

enum TileRotation {
	ZERO,
	NINETY,
	ONE_EIGHTY,
	TWO_SEVENTY
}

const MAX_ROOM_PLACEMENT_ATTEMPTS := 5
const CELL_LENGTH := 32
const CELL_WIDTH := 32
const CELL_HEIGHT := 16
const CELL_DIMENSIONS := Vector3i(CELL_LENGTH, CELL_HEIGHT, CELL_WIDTH)
const HALLWAY_OFFSET := -3*Vector3i(CELL_LENGTH, 0, CELL_WIDTH)/8
@export_range(1, 32) var cells_wide := 32
@export_range(1, 64) var cells_long := 64
@export_range(1, 8) var cells_tall := 8

@export var max_rooms: int

@export var rng_seed: int

@export var minimum_timer := 1200.0
@export var maximum_timer := 1800.0

@export var hallway_library: HallwayLibrary
@export var room_library: RoomLibrary

@export var generate_ship := false: 
	set(value):
		if value:
			clear()
			generate()
		generate_ship = false

@export var clear_ship := false:
	set(value):
		if value:
			clear()
		clear_ship = false

@onready var rooms: Node3D = $Rooms
@onready var hallways: Node3D = $Hallways

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

func clear() -> void:
	for room in rooms.get_children():
		if not room is ShipCell:
			push_error("Room isn't a ShipCell!")
		if not room.is_prespawn:
			room.queue_free()
	for child in hallways.get_children():
		child.queue_free()
	_tile_map = {}
	_rng = null

func _ready():
	cell_at_infinity = Vector3i(cells_long + 1, cells_tall + 1, cells_wide + 1)
	if not Engine.is_editor_hint():
		_rng = RandomNumberGenerator.new()
		if rng_seed == 0:
			_rng.randomize()
			rng_seed = _rng.seed
		else:
			_rng.seed = rng_seed
		generate()



static func _global_to_hallway(pos: Vector3) -> Vector3i:
	return (Vector3i(pos - Vector3(HALLWAY_OFFSET))) * 4 / CELL_DIMENSIONS


static func _global_to_cell(pos: Vector3) -> Vector3i:
	return Vector3i(pos) / CELL_DIMENSIONS


static func _cell_to_global(pos: Vector3i) -> Vector3:
	return pos * CELL_DIMENSIONS


static func _hallway_to_global(pos: Vector3i) -> Vector3:
	return pos * CELL_DIMENSIONS/4 + HALLWAY_OFFSET


func _add_room(p_tile: RoomSpawnMetadata, p_position: Vector3i, tile_rotation: TileRotation = TileRotation.ZERO) -> Error:
	# TODO: Change
	if _tile_map.has(p_position) \
	or _tile_map.has(p_position + Vector3i(1,0,0)) \
	or _tile_map.has(p_position + Vector3i(-1,0,0)) \
	or _tile_map.has(p_position + Vector3i(0,0,1)) \
	or _tile_map.has(p_position + Vector3i(0,0,-1)) \
	or _tile_map.has(p_position + Vector3i(1,0,-1)) \
	or _tile_map.has(p_position + Vector3i(1,0,1)) \
	or _tile_map.has(p_position + Vector3i(-1,0,-1)) \
	or _tile_map.has(p_position + Vector3i(-1,0,1)):
		return ERR_ALREADY_IN_USE
	var instantiated_tile: ShipCell = p_tile.room.instantiate()
	instantiated_tile.position = _cell_to_global(p_position)
	var angle: float = 0
	match tile_rotation:
		TileRotation.ZERO:
			angle = 0
		TileRotation.NINETY:
			angle = PI/2
		TileRotation.ONE_EIGHTY:
			angle=PI
		TileRotation.TWO_SEVENTY:
			angle = -PI/2
	instantiated_tile.rotation = Vector3(0,angle,0)
	rooms.add_child(instantiated_tile)
	print('Tile location: %s Tile size: %s' % [p_position, p_tile.cell_size])
	for x in p_tile.cell_size.x:
		for y in p_tile.cell_size.y:
			for z in p_tile.cell_size.z:
				_tile_map[p_position + Vector3i(Vector3(x,y,z).rotated(Vector3.UP,angle))] = instantiated_tile
	return OK

func _is_box_valid(box_location: Vector3i, box_size: Vector3i) -> bool:
	for x in box_size.x:
		for y in box_size.y:
			for z in box_size.z:
				var test_location := box_location + Vector3i(x,y,z)
				if _tile_map.has(test_location) or test_location.x >= cells_wide or test_location.y >= cells_tall or test_location.z >= cells_long:
					return false
	return true

func _compute_coords_array(room_size: Vector3i) -> Array[Vector3i]:
	var res: Array[Vector3i] = []
	for x in cells_wide:
		for y in cells_tall:
			for z in cells_long:
				if _is_box_valid(Vector3i(x,y,z), room_size):
					res.append(Vector3i(x,y,z))
	return res

func _generate_rooms() -> void:
	# TODO: add the in editor rooms into the map
	for i in max_rooms:
		var room_tile := room_library.rooms[_rng.randi_range(0, room_library.rooms.size() - 1)]
		var cell_size := room_tile.get_cell_size()
		var possible_coords := _compute_coords_array(cell_size)
		var other_possible_coords := _compute_coords_array(Vector3i(cell_size.z, cell_size.y, cell_size.x))
		var weights: PackedFloat32Array = PackedFloat32Array()
		weights.resize(possible_coords.size() + other_possible_coords.size())
		weights.fill(1.0)
		var attempt := 0
		while attempt < weights.size():
			attempt += 1
			var chosen_coord_idx := _rng.rand_weighted(weights)
			weights[chosen_coord_idx] = 0.0
			var chosen_coord: Vector3i
			var room_rotation: TileRotation
			if chosen_coord_idx < possible_coords.size():
				chosen_coord = possible_coords[chosen_coord_idx]
				room_rotation = TileRotation.ZERO if _rng.randf() < 0.5 else TileRotation.ONE_EIGHTY
			else:
				chosen_coord = other_possible_coords[chosen_coord_idx - possible_coords.size()]
				room_rotation = TileRotation.NINETY if _rng.randf() < 0.5 else TileRotation.TWO_SEVENTY
			var add_room_err: int
			for j in 2:
				var rot_correction := Vector3i(0,0,0)
				# TODO: There's definitely a bug here but I'm not quite sure I can sniff it out without more varied tile sizes
				match room_rotation:
					TileRotation.NINETY:
						rot_correction.z += cell_size.z - 1
					TileRotation.ONE_EIGHTY:
						rot_correction.x += cell_size.x - 1
						rot_correction.z += cell_size.z - 1
					TileRotation.TWO_SEVENTY:
						pass
						#rot_correction.x += cell_size.x - 1
				add_room_err = _add_room(room_tile, chosen_coord + rot_correction, room_rotation)
				if add_room_err == OK:
					break
				match room_rotation:
					TileRotation.ZERO:
						room_rotation = TileRotation.ONE_EIGHTY
					TileRotation.NINETY:
						room_rotation = TileRotation.TWO_SEVENTY
					TileRotation.ONE_EIGHTY:
						room_rotation = TileRotation.ZERO
					TileRotation.TWO_SEVENTY:
						room_rotation = TileRotation.NINETY
			if add_room_err == OK:
				break


func _generate_room_mst() -> Dictionary:
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
	return res


func _hallway_cell_is_in_room(hallway_coord: Vector3i) -> bool:
	var cell_coord := hallway_coord/4
	return _tile_map.has(cell_coord)


func _generate_hallway_astar() -> AStar3D:
	var astar := ShipAStar3D.new()
	astar.reserve_space(64 * cells_long * cells_tall * cells_wide)
	var id := 0
	for x in 4 * cells_wide:
		for y in 4 * cells_tall:
			for z in 4 * cells_long:
				# Check if this vertex is interior to a room
				# Do not add if it is
				var pos := _hallway_to_global(Vector3i(x, y, z))
				if not _hallway_cell_is_in_room(Vector3i(x,y,z)):
					astar.add_point(id, pos)
				id += 1
	id = 0
	for x in 4 * cells_wide:
		for y in 4 * cells_tall:
			for z in 4 * cells_long:
				if _hallway_cell_is_in_room(Vector3i(x,y,z)):
					id += 1
					continue
				if z != 4 * cells_long - 1 and not _hallway_cell_is_in_room(Vector3i(x,y,z+1)):
					astar.connect_points(id, id+1)
				if y != 4 * cells_tall - 1 and not _hallway_cell_is_in_room(Vector3i(x, y+1, z)):
					if z != 4 * cells_long - 1 and not _hallway_cell_is_in_room(Vector3i(x, y+1, z+1)) and x % 2 == 0:
						astar.connect_points(id, id + 4 * cells_long + 1)
					if z != 0 and not _hallway_cell_is_in_room(Vector3i(x,y+1, z-1)) and x % 2 == 1:
						astar.connect_points(id, id + 4 * cells_long - 1)
					if x != 4 * cells_wide - 1 and not _hallway_cell_is_in_room(Vector3i(x+1, y+1, z)) and z % 2 == 0:
						astar.connect_points(id, id + 4 * cells_long + 16*cells_tall * cells_long)
					if x != 0 and not _hallway_cell_is_in_room(Vector3i(x-1, y+1, z)) and z % 2 == 1:
						astar.connect_points(id, id + 4 * cells_long - 16 * cells_tall * cells_long)
				if x != 4 * cells_wide - 1 and not _hallway_cell_is_in_room(Vector3i(x+1, y, z)):
					astar.connect_points(id, id + 16 * cells_tall * cells_long)
				id += 1
	return astar

## Finds the door in from_cell whose vector most closely aligns with from_cell
func _pick_door(from_cell: ShipCell, to_cell: ShipCell) -> Dictionary:
	if from_cell.doors.size() == 0:
		return {'cell_offset': Vector3(-1, -1, -1), 'door_idx': -1}
	var room_dir := (to_cell.global_position - from_cell.global_position).normalized()
	var best_door_idx := -1
	var best_cell_offset := Vector3(-1, -1, -1)
	var best_door_alignment := -2.0
	for cell_offset in from_cell.doors:
		for door in from_cell.doors[cell_offset]:
			var door_idx: int = door.offset_idx
			var door_dir := (from_cell.door_global_pos(cell_offset, door_idx) - from_cell.get_global_center()).normalized()
			if door_dir.dot(room_dir) > best_door_alignment:
				best_door_idx = door_idx
				best_cell_offset = cell_offset
				best_door_alignment = door_dir.dot(room_dir)
	return {'cell_offset': best_cell_offset, 'door_idx': best_door_idx}


func _generate_hallway_graph(astar: AStar3D, room_mst: Dictionary) -> Dictionary:
	var hallway_graph := {}
	for vert in room_mst:
		if room_mst[vert] == cell_at_infinity:
			print("not connecting root %s to %s" % [vert, room_mst[vert]])
			continue
		var from_cell := _tile_map[vert] as ShipCell
		var to_cell := _tile_map[room_mst[vert]] as ShipCell
		var from_door := _pick_door(from_cell, to_cell)
		var to_door := _pick_door(to_cell, from_cell)
		var from := astar.get_closest_point(from_cell.door_global_pos(from_door.cell_offset, from_door.door_idx))
		var to := astar.get_closest_point(to_cell.door_global_pos(to_door.cell_offset, to_door.door_idx))
		var point_path := astar.get_point_path(from, to)
		for i in point_path.size()-1:
			var hallway_from := _global_to_hallway(point_path[i])
			if not hallway_graph.has(hallway_from):
				hallway_graph[hallway_from] = []
			var hallway_to := _global_to_hallway(point_path[i+1])
			if not hallway_graph.has(hallway_to):
				hallway_graph[hallway_to] = []
			if not hallway_to in hallway_graph[hallway_from]:
				hallway_graph[hallway_from].append(hallway_to)
			if not hallway_from in hallway_graph[hallway_to]:
				hallway_graph[hallway_to].append(hallway_from)
			if i == 0 and from_door.door_idx != -1 and not hallway_graph[hallway_from].has(hallway_from + from_cell.get_door_hallway_offset(from_door.door_idx)):
				hallway_graph[hallway_from].append(hallway_from + from_cell.get_door_hallway_offset(from_door.door_idx))
			elif i == point_path.size() - 2 and not hallway_graph[hallway_to].has(hallway_to + to_cell.get_door_hallway_offset(to_door.door_idx)):
				hallway_graph[hallway_to].append(hallway_to + to_cell.get_door_hallway_offset(to_door.door_idx))
			#if z != 4 * cells_long - 1 and not _hallway_cell_is_in_room(Vector3i(x, y+1, z+1)):
				#astar.connect_points(id, id + 4 * cells_long + 1)
			#if z != 0 and not _hallway_cell_is_in_room(Vector3i(x,y+1, z-1)):
				#astar.connect_points(id, id + 4 * cells_long - 1)
			#if x != 4 * cells_wide - 1 and not _hallway_cell_is_in_room(Vector3i(x+1, y+1, z)):
				#astar.connect_points(id, id + 4 * cells_long + 16*cells_tall * cells_long)
			#if x != 0 and not _hallway_cell_is_in_room(Vector3i(x-1, y+1, z)):
				#astar.connect_points(id, id + 4 * cells_long + 16 * cells_tall * cells_long)
			# snip snip relevant edges
			if is_equal_approx(point_path[i].y, point_path[i+1].y):
				if not _global_to_hallway(point_path[i]).y == 4*cells_tall - 1:
					if not _hallway_cell_is_in_room(_global_to_hallway(point_path[i] + Vector3(0,4,0))):
						astar.disconnect_points(astar.get_closest_point(point_path[i+1]), astar.get_closest_point(point_path[i] + Vector3(0,4,0)))
					if not _hallway_cell_is_in_room(_global_to_hallway(point_path[i+1] + Vector3(0,4,0))):
						astar.disconnect_points(astar.get_closest_point(point_path[i]), astar.get_closest_point(point_path[i+1] + Vector3(0,4,0)))
				if not _global_to_hallway(point_path[i]).y == 0:
					if not _hallway_cell_is_in_room(_global_to_hallway(point_path[i] - Vector3(0,4,0))):
						astar.disconnect_points(astar.get_closest_point(point_path[i+1]), astar.get_closest_point(point_path[i] - Vector3(0,4,0)))
					if not _hallway_cell_is_in_room(_global_to_hallway(point_path[i+1] - Vector3(0,4,0))):
						astar.disconnect_points(astar.get_closest_point(point_path[i]), astar.get_closest_point(point_path[i+1] - Vector3(0,4,0)))
			else:
				var lower := point_path[i] if point_path[i].y < point_path[i+1].y else point_path[i+1]
				var upper := point_path[i] if point_path[i].y > point_path[i+1].y else point_path[i+1]
				if _global_to_hallway(lower).y != 4*cells_tall - 1 and not _hallway_cell_is_in_room(_global_to_hallway(lower + Vector3(0,4,0))):
					astar.disconnect_points(astar.get_closest_point(upper), astar.get_closest_point(lower + Vector3(0,4,0)))
				if _global_to_hallway(lower).y != 4*cells_tall - 2 and not _hallway_cell_is_in_room(_global_to_hallway(lower + Vector3(0,8,0))):
					astar.disconnect_points(astar.get_closest_point(upper), astar.get_closest_point(lower + Vector3(0,8,0)))
				if _global_to_hallway(upper).y != 0 and not _hallway_cell_is_in_room(_global_to_hallway(upper - Vector3(0,4,0))):
					astar.disconnect_points(astar.get_closest_point(lower), astar.get_closest_point(upper - Vector3(0,4,0)))
				if _global_to_hallway(upper).y != 2 and not _hallway_cell_is_in_room(_global_to_hallway(upper - Vector3(0,8,0))):
					astar.disconnect_points(astar.get_closest_point(lower), astar.get_closest_point(upper - Vector3(0,8,0)))
			#_draw_line(point_path[i] + Vector3(0,2,0), point_path[i+1] + Vector3(0,2,0))

	return hallway_graph


func _generate_hallways(hallway_graph: Dictionary) -> void:
	#print(hallway_graph)
	for hallway_vertex in hallway_graph:
		var hallway: Node3D = null
		var is_ramp := false
		match hallway_graph[hallway_vertex].size():
			1:
				hallway = hallway_library.cap.instantiate()
				var cap_dir: Vector3i = hallway_vertex - hallway_graph[hallway_vertex][0]
				hallway.look_at_from_position(Vector3(0,0,0), cap_dir)
			2:
				var first_dir := Vector3(hallway_vertex - hallway_graph[hallway_vertex][0])
				var second_dir := Vector3(hallway_vertex - hallway_graph[hallway_vertex][1])
				var projected_first_dir := (first_dir - first_dir.project(Vector3.UP)).normalized()
				var projected_second_dir := (second_dir - second_dir.project(Vector3.UP)).normalized()
				var look_dir := projected_first_dir if hallway_graph[hallway_vertex][0].y > hallway_graph[hallway_vertex][1].y else projected_second_dir
				var other_look_dir := projected_second_dir if hallway_graph[hallway_vertex][0].y > hallway_graph[hallway_vertex][1].y else projected_first_dir
				var max_y: float = [hallway_vertex.y, hallway_graph[hallway_vertex][0].y, hallway_graph[hallway_vertex][1].y].max()
				var should_ramp: bool = [hallway_vertex, hallway_graph[hallway_vertex][0], hallway_graph[hallway_vertex][1]].reduce(func(accum, vert): return accum + (1 if is_equal_approx(vert.y, max_y) else 0), 0) == 2
				should_ramp = should_ramp or not is_equal_approx(hallway_vertex.y, hallway_graph[hallway_vertex][0].y) and not is_equal_approx(hallway_vertex.y, hallway_graph[hallway_vertex][1].y) and not is_equal_approx(hallway_graph[hallway_vertex][1].y, hallway_graph[hallway_vertex][0].y)
				if is_equal_approx(abs(hallway_graph[hallway_vertex][0].y - hallway_graph[hallway_vertex][1].y), 0) or not should_ramp: 
					if not is_zero_approx(projected_first_dir.dot(projected_second_dir)):
						hallway = hallway_library.straight.instantiate()
						hallway.look_at_from_position(Vector3(0,0,0), look_dir)
					else:
						hallway = hallway_library.turn.instantiate()
						if Vector3(first_dir).cross(second_dir).y > 0:
							hallway.look_at_from_position(Vector3(0,0,0), projected_second_dir)
						else:
							hallway.look_at_from_position(Vector3(0,0,0), projected_first_dir)
				else:
					if not is_zero_approx(projected_first_dir.dot(projected_second_dir)):
						hallway = hallway_library.straight.instantiate()
						hallway.look_at_from_position(Vector3(0,0,0), look_dir)
						is_ramp = true
					elif look_dir.cross(other_look_dir).y > 0:
						hallway = hallway_library.turn.instantiate()
						hallway.look_at_from_position(Vector3(0,0,0), other_look_dir)
						is_ramp = true
					else:
						hallway = hallway_library.turn.instantiate()
						hallway.look_at_from_position(Vector3(0,0,0), other_look_dir)
						is_ramp = true
			3:
				hallway = hallway_library.three_way.instantiate()
				var first_dir := Vector3(hallway_vertex - hallway_graph[hallway_vertex][0])
				var projected_first_dir := (first_dir - first_dir.project(Vector3.UP)).normalized()
				var second_dir := Vector3(hallway_vertex - hallway_graph[hallway_vertex][1])
				var projected_second_dir := (second_dir - second_dir.project(Vector3.UP)).normalized()
				var third_dir := Vector3(hallway_vertex - hallway_graph[hallway_vertex][2])
				var projected_third_dir := (third_dir - third_dir.project(Vector3.UP)).normalized()
				var perpindicular_dir: Vector3i
				if Vector3(projected_first_dir).dot(projected_second_dir):
					perpindicular_dir = projected_third_dir
				elif Vector3(projected_first_dir).dot(projected_third_dir):
					perpindicular_dir = projected_second_dir
				else:
					perpindicular_dir = projected_first_dir
				hallway.look_at_from_position(Vector3(0,0,0), perpindicular_dir)
			4:
				hallway = hallway_library.four_way.instantiate()
			_:
				print('too many vertices')
		if hallway:
			hallway.position = _hallway_to_global(hallway_vertex) + Vector3(0,0,0) if is_ramp else _hallway_to_global(hallway_vertex)
			hallways.add_child(hallway)


func generate():
	print('generating')
	if not _rng:
		_rng = RandomNumberGenerator.new()
		if rng_seed == 0:
			_rng.randomize()
		else:
			_rng.seed = rng_seed
	_generate_rooms()
	var room_mst := _generate_room_mst()
	#for vert in room_mst:
		#if room_mst[vert] == cell_at_infinity:
			#continue
		#_draw_line(_cell_to_global(vert), _cell_to_global(room_mst[vert]), Color.BLUE)
	var astar := _generate_hallway_astar()
	var hallway_graph := _generate_hallway_graph(astar, room_mst)
	_generate_hallways(hallway_graph)
	
	if Engine.is_editor_hint():
		_rng = null


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
