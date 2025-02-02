@tool
extends Area3D
class_name ShipCell

@export_range(1, 6) var cells_x := 1:
	set(value):
		cells_x = value
		if is_node_ready():
			_calculate_box_size()
			_setup_nav_regions()

@export_range(1, 6) var cells_y := 1:
	set(value):
		cells_y = value
		if is_node_ready():
			_calculate_box_size()
			_setup_nav_regions()

@export_range(1, 6) var cells_z := 1:
	set(value):
		cells_z = value
		if is_node_ready():
			_calculate_box_size()
			_setup_nav_regions()

var is_prespawn := false

@export var doors: Dictionary = {}

@onready var bounding_area: CollisionShape3D = %Box
@onready var nav_geometry: StaticBody3D = %ExtraNavGeometry
@onready var small_nav: NavigationRegion3D = %SmallAgentNavRegion
@onready var medium_nav: NavigationRegion3D = %MediumAgentNavRegion
@onready var large_nav: NavigationRegion3D = %LargeAgentNavRegion


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

func get_door_hallway_offset(hallway_offset_idx: int) -> Vector3i:
	var offset := Vector3(door_hallway_offsets[hallway_offset_idx]).rotated(Vector3.UP, rotation.y)
	return Vector3i(offset)
	

var editor_bubbles: Node3D

func _ready():
	small_nav.set_navigation_map(RiggedGlobals.small_map_rid)
	large_nav.set_navigation_map(RiggedGlobals.large_map_rid)
	if Engine.is_editor_hint():
		_calculate_box_size()
		_setup_nav_regions()


func door_global_pos(cell_index: Vector3, door_idx: int) -> Vector3:
	if door_idx == -1 or cell_index.is_equal_approx(Vector3(-1, -1, -1)):
		return get_global_center()
	return global_position + (cell_index * Vector3(32, 16, 32) + door_offsets[door_idx]).rotated(Vector3.UP, rotation.y)

func get_global_center() -> Vector3:
	return global_position + (Vector3(cells_x-1, cells_y-1, cells_z-1) * Vector3(16, 8, 16)).rotated(Vector3.UP, rotation.y)

func is_valid_door_pos(cell_coord: Vector3i, door_idx: int) -> bool:
	var offset := door_offsets[door_idx]
	var x_invalid := offset.x > 12 and cell_coord.x != cells_x - 1 or offset.x < -12 and cell_coord.x != 0
	var z_invalid := offset.z > 12 and cell_coord.z != cells_z - 1 or offset.z < -12 and cell_coord.z != 0
	return not x_invalid and not z_invalid
	

func _calculate_box_size():
	if not bounding_area:
		print('box is nil???')
	var box: BoxShape3D = bounding_area.shape
	box.size = Vector3(cells_x * 32, cells_y * 16, cells_z * 32)
	bounding_area.position = Vector3((cells_x-1)*16, cells_y * 8, (cells_z-1)*16)
	var doors_to_remove := []
	for cell in doors:
		for door in doors[cell]:
			if not is_valid_door_pos(cell, door.offset_idx):
				doors_to_remove.push_back({'cell': cell, 'offset_idx': door.offset_idx})
	for door in doors_to_remove:
		remove_door(door.cell, door.offset_idx)
	if get_tree().edited_scene_root == self:
		_draw_editor_bubbles()

func _validate_property(property: Dictionary) -> void:
	if property.name in ['is_prespawn']:
		property.usage = PROPERTY_USAGE_STORAGE

func _setup_nav_regions() -> void:
	if get_tree().edited_scene_root != self:
		return
	for nav in [small_nav, medium_nav, large_nav]:
		if not nav.navigation_mesh:
			var new_mesh := NavigationMesh.new()
			new_mesh.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
			new_mesh.geometry_collision_mask = 0
			new_mesh.set_collision_mask_value(32, true)
			new_mesh.geometry_source_geometry_mode = NavigationMesh.SOURCE_GEOMETRY_GROUPS_WITH_CHILDREN
			new_mesh.geometry_source_group_name = 'navigation_mesh_source_group'
			new_mesh.border_size = 2
			nav.navigation_mesh = new_mesh
		# lhw: cells_x*32, cells_y*16, cells_z*32 + 2*border, 0, 2*border
		# position: -lhw/2
		var filter_aabb := AABB(Vector3(-(cells_x*32 + 4)/2.0 + (cells_x - 1) * 16,0,-(cells_z*32+4)/2.0 + 16*(cells_z-1)), Vector3(cells_x * 32 + 8,cells_y*16,cells_z*32 + 4))
		nav.navigation_mesh.filter_baking_aabb = filter_aabb
	small_nav.navigation_mesh.agent_radius = 0.5
	medium_nav.navigation_mesh.agent_radius = 1.0
	large_nav.navigation_mesh.agent_radius = 1.5
	small_nav.bake_navigation_mesh()
	medium_nav.bake_navigation_mesh()
	large_nav.bake_navigation_mesh()

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED and editor_bubbles != null:
		editor_bubbles.transform = transform

func _draw_editor_bubbles():
	if not editor_bubbles:
		editor_bubbles = Node3D.new()
		get_parent().add_child(editor_bubbles)
		editor_bubbles.transform = transform
	for child in editor_bubbles.get_children():
		child.queue_free()

	for x in cells_x:
		for y in cells_y:
			for z in cells_z:
				for offset_idx in door_offsets.size():
					var offset := door_offsets[offset_idx]
					if is_valid_door_pos(Vector3i(x,y,z), offset_idx):
						var cell_pos = Vector3(x*32,y*8,z*32)
						var ball_scene := preload("res://addons/clickable_ball/clickable_ball.tscn")
						var ball := ball_scene.instantiate()
						var cell_coords := Vector3i(x,y,z)
						ball.clicked.connect(_on_bubble_input_event.bind(ball, Vector3i(x,y,z), offset_idx))
						ball.position = cell_pos + offset
						editor_bubbles.add_child(ball)
						if has_door(cell_coords, offset_idx):
							ball.set_color(Color.BLUE)
						else:
							ball.set_color(Color.RED)

func _on_bubble_input_event(ball: ClickableBall, cell_coord: Vector3i, offset_idx: int):
	if has_door(cell_coord, offset_idx):
		remove_door(cell_coord, offset_idx)
		ball.set_color(Color.RED)
	else:
		add_door(cell_coord, offset_idx)
		ball.set_color(Color.BLUE)
	await get_tree().physics_frame
	await get_tree().physics_frame
	_setup_nav_regions()


func has_door(cell_coord: Vector3i, offset_idx: int) -> bool:
	if not cell_coord in doors:
		return false
	for door in doors[cell_coord]:
		if door.offset_idx == offset_idx:
			return true 
	return false

func add_door(cell_coord: Vector3i, offset_idx: int):
	assert(not has_door(cell_coord, offset_idx))
	if not cell_coord in doors:
		doors[cell_coord] = []
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(4.5, 0.2, 4.5)
	collider.shape = shape
	var max_component_idx := -1
	for i in 3:
		if max_component_idx == -1 or abs(door_offsets[offset_idx][i]) > abs(door_offsets[offset_idx][max_component_idx]):
			max_component_idx = i
	var offset := door_offsets[offset_idx]
	offset[max_component_idx] = offset[max_component_idx] - 1.75 * sign(offset[max_component_idx])
	collider.position = Vector3((cell_coord.x) * 32, cell_coord.y*8, ((cell_coord.z)*32)) + offset
	collider.name = "DoorFloor"
	nav_geometry.add_child(collider, true)
	collider.owner = get_tree().edited_scene_root
	var door_dict := {'collider': get_path_to(collider), 'offset_idx': offset_idx}
	doors[cell_coord].push_back(door_dict)
	notify_property_list_changed()

func remove_door(cell_coord: Vector3i, offset_idx: int):
	assert(has_door(cell_coord, offset_idx))
	for door in doors[cell_coord]:
		if door.offset_idx == offset_idx:
			doors[cell_coord].erase(door)
			get_node(door.collider).queue_free()
			break
	if doors[cell_coord].size() == 0:
		doors.erase(cell_coord)
	notify_property_list_changed()

func _enter_tree() -> void:
	if is_node_ready():
		_calculate_box_size()

func _exit_tree() -> void:
	if editor_bubbles:
		editor_bubbles.queue_free()
		editor_bubbles = null
