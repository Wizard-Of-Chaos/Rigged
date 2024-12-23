extends Node
class_name Inventory

var slots_x: int = 4
var slots_y: int = 3
var grid = []

#TODO: Add 'cell' class, maybe? and figure out how to set up this grid properly.
func _ready():
	for i in slots_x:
		grid.append([])
		for j in slots_y:
			grid[i].append(0)
