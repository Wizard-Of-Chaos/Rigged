extends Node
class_name Health

@export var current_health: int = 500
@export var max_health: int = 500
 
func damage(dmg: int):
	if dmg < 0:
		return
	current_health -= dmg
	

func _ready():
	pass

func _process(delta):
	if max_health <= 0:
		#kill this fucking thing
		pass
