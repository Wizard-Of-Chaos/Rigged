extends Node
class_name Interactable

signal interacted(Player)

func _interact(clicker: Player):
	interacted.emit(clicker)
	print("This node has been interacted with")
	pass
