extends Node
class_name Inventory

const InventoryItem = preload("res://scripts/items/inventory_base.gd")
const GridCell = preload("res://scenes/actors/inventory/grid_cell.gd")

@export var slots_x: int = 4
@export var slots_y: int = 3
var grid = []

func _ready():
	grid.clear()
	for i in range(slots_x):
		var row = []
		for j in range(slots_y):
			row.append(GridCell.new())
		grid.append(row)
	
	load_test_inventory()

func add_item(item: InventoryItem) -> bool:


	if grid == []:
		return false
	
	for i in range(slots_x):
		if i >= len(grid):
			return false

		for j in range(slots_y):
			if j >= len(grid[i]):
				return false

			if grid[i][j].item == null:
				grid[i][j].item = item
				grid[i][j].quantity = item.quantity
				
				return true

	return false

func has_item(item_name: String) -> bool:
	for row in grid:
		for cell in row:
			if cell.item and cell.item.name == item_name:
				return true
	return false

func print_inventory():
	for row in grid:
		for cell in row:
			if cell.item:
				print("Slot contains:", cell.item.name, "(x", cell.quantity, ")")

func load_test_inventory():
	var test_inventory = load("res://scenes/actors/inventory/player_test_inventory_set.gd").new()
	for item in test_inventory.get_starting_inventory():
		add_item(item)
