class_name SerializationInfo
extends Resource

@export var name: String

func _init(name: String = ""):
	self.name = name

func _size() -> int:
	assert(false, "UNIMPLEMENTED")
	return 0
