class_name QuaternionInfo 
extends SerializationInfo

@export var float_info: FloatInfo

func _init(p_name: String = "", p_info: FloatInfo = null, p_use_smallest_three: bool = false):
	super(name)
	self.float_info = p_info


func _size() -> int:
	return 0
