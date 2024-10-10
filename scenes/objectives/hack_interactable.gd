class_name HackInteractable extends Interactable
@onready var hack_obj: HackObjective = %HackObjective 
func _interact(clicker: Player):
	interacted.emit(clicker)
	print("Hacking this node!")
	hack_obj.activated = true
	pass

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
