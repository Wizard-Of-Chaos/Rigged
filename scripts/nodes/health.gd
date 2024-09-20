extends Node
class_name Health

signal health_changed(old_health: int, new_health: int)

@export var current_health: int = 500:
	set(value):
		health_changed.emit(current_health, value)
		current_health = value
@export var max_health: int = 500
 
func damage(dmg: int):
	if dmg < 0:
		return
	current_health -= dmg
	

func _ready():
	pass
