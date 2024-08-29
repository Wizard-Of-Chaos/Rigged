class_name Vector3Info 
extends SerializationInfo

@export var info: FloatInfo

func _init(p_name: String = "", p_info: FloatInfo = null):
	super(p_name)
	info = p_info
