extends Resource
class_name PlayerTestInventory

const Equipment = preload("res://scripts/items/equipment_base.gd")
const InventoryItem = preload("res://scripts/items/inventory_base.gd")

func get_starting_inventory() -> Array:
	return [
		preload("res://scripts/items/medkit.gd").new(),
		preload("res://scripts/items/ammo_pack.gd").new()
	]

func get_starting_equipment() -> Dictionary:
	return {
		0: load("res://scripts/items/helmet.gd").new() if ResourceLoader.exists("res://scripts/items/helmet.gd") else Equipment.new(),
		1: load("res://scripts/items/armor.gd").new() if ResourceLoader.exists("res://scripts/items/armor.gd") else Equipment.new(),
		2: load("res://scripts/items/gauntlets.gd").new() if ResourceLoader.exists("res://scripts/items/gauntlets.gd") else Equipment.new(),
		3: load("res://scripts/items/greaves.gd").new() if ResourceLoader.exists("res://scripts/items/greaves.gd") else Equipment.new(),
		4: load("res://scripts/items/backpack.gd").new() if ResourceLoader.exists("res://scripts/items/backpack.gd") else Equipment.new(),
		5: load("res://scripts/items/rifle.gd").new() if ResourceLoader.exists("res://scripts/items/rifle.gd") else Equipment.new(),
		6: load("res://scripts/items/pistol.gd").new() if ResourceLoader.exists("res://scripts/items/pistol.gd") else Equipment.new()
	}
