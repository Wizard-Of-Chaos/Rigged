extends Interactable
class_name Elevator

@onready var elevator_floor: CSGBox3D = $".."

const floors: int = 2
var current_floor: int = 0
var tween: Tween

func _interact(clicker: Player):
	print("Elevator clicked.")
	if tween.is_running():
		return # don't change it up when we're currently elevating
		
	interacted.emit(clicker)
	if tween:
		tween.kill()
	tween = get_tree().create_tween()
	if current_floor == 0:
		tween.tween_property(elevator_floor, "position", elevator_floor.position + Vector3(0,16,0), 1.0)
		current_floor = 1
	elif current_floor == 1:
		tween.tween_property(elevator_floor, "position", elevator_floor.position - Vector3(0,16,0), 1.0)
