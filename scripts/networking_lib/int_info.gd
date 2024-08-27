class_name IntInfo 
extends SerializationInfo


@export var min_value: int
@export var max_value: int


var num_bits: int


func _init(p_name: String = "", p_min_value: int = 0, p_max_value: int = 0):
	super(p_name)
	self.min_value = p_min_value
	self.max_value = p_max_value
