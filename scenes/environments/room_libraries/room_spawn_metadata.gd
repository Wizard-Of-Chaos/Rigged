@tool
class_name RoomSpawnMetadata
extends Resource

enum Sectors {
	ENGINEERING,
	CREW_QUARTERS,
	CARGO
}

enum SectorSpawnType {
	NONE,
	WHITELIST,
	BLACKLIST
}

@export var room: PackedScene:
	set(value):
		room = value
		cell_size = get_cell_size()
		notify_property_list_changed()
@export var can_random_spawn: bool:
	set(value):
		can_random_spawn = value
		notify_property_list_changed()
@export var spawn_weight: float = 1
@export var max_instances: int

@export var sector_spawn_type: SectorSpawnType:
	set(value):
		sector_spawn_type = value
		notify_property_list_changed()
var sector_list: Array[Sectors]
var cell_size: Vector3i

func _validate_property(property: Dictionary) -> void:
	#print(property)
	if property.name == 'sector_list' and can_random_spawn and sector_spawn_type in [SectorSpawnType.WHITELIST, SectorSpawnType.BLACKLIST]:
		property.usage |= (PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE)
		property.hint = 23
		property.hint_string = _sector_list_hint_string()
	elif property.name == 'cell_size':
		property.usage = PROPERTY_USAGE_STORAGE
	
	if property.name in ['max_instances', 'spawn_weight', 'sector_spawn_type']:
		if can_random_spawn:
			property.usage |= (PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_STORAGE)
		else:
			property.usage &= ~(PROPERTY_USAGE_EDITOR)

func _sector_list_hint_string() -> String:
	var enum_string := ""
	for sector in Sectors:
		enum_string += "%s:%d," % [sector.capitalize(), Sectors[sector]]
	enum_string = enum_string.substr(0, enum_string.length()-1)
	return "%d/%d:%s" % [TYPE_INT,PROPERTY_HINT_ENUM, enum_string]


func get_cell_size() -> Vector3i:
	if room == null:
		return Vector3i(0,0,0)
	var packed_state := room.get_state()
	var result := Vector3i(1,1,1)
	for node_prop_idx in packed_state.get_node_property_count(0):
		var prop_name := packed_state.get_node_property_name(0, node_prop_idx)
		if prop_name == 'cells_x':
			result.x = packed_state.get_node_property_value(0, node_prop_idx)
		elif prop_name == 'cells_y':
			result.y = packed_state.get_node_property_value(0, node_prop_idx)
		elif prop_name == 'cells_z':
			result.z = packed_state.get_node_property_value(0, node_prop_idx)
	return result
