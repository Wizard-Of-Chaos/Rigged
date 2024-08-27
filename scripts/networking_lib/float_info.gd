class_name FloatInfo 
extends SerializationInfo


@export var min_value: float:
	set(value):
		assert(value < self.max_value)
		min_value = value
		self._recalculate_derived_values()


@export var max_value: float:
	set(value):
		assert(value > self.min_value)
		max_value = value
		self._recalculate_derived_values()


@export var values_per_unit: int:
	set(value):
		values_per_unit = value
		self._recalculate_derived_values()


var resolution: float
var inv_diff: float
var num_bits: int


func _init(p_name: String = "", p_min_value: float = 0.0, p_max_value: float = 1.0, p_values_per_unit: int = 1):
	super(p_name)
	self.min_value = p_min_value
	self.max_value = p_max_value
	self.values_per_unit = p_values_per_unit


func _recalculate_derived_values():
	self.inv_diff = 1/(self.max_value - self.min_value)
	self.resolution = self.values_per_unit * (self.max_value - self.min_value)
	self.num_bits = ceili(log(self.resolution + 1) / log(2))
