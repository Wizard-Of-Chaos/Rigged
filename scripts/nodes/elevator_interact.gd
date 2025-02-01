extends Interactable
class_name Elevator

@onready var elevator_floor: CSGBox3D = %Floor
const floors: int = 2
var current_floor: int = 0
var tween: Tween

func _interact(clicker: Player):
	print("Elevator clicked... ")		
	interacted.emit(clicker)
	if tween:
		if tween.is_running():
			print("ignoring.")
			return # don't change it up when we're currently elevating

		tween.kill()
	tween = get_tree().create_tween()
	if current_floor == 0:
		print("ascending.")
		tween.tween_property(elevator_floor, "position", elevator_floor.position + Vector3(0,16,0), 4.5).set_trans(Tween.TRANS_SINE)
		current_floor = 1
	elif current_floor == 1:
		print("descending.")
		tween.tween_property(elevator_floor, "position", elevator_floor.position - Vector3(0,16,0), 4.5).set_trans(Tween.TRANS_SINE)
		current_floor = 0
