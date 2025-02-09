extends Resource
class_name GridCell

const InventoryItem = preload("res://scripts/items/inventory_base.gd")

@export var item: InventoryItem = null
@export var quantity: int = 1
