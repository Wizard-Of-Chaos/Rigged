extends Node
class_name EquipmentSystem

const Equipment = preload("res://scripts/items/equipment_base.gd")

enum SlotType { HEAD, ARMOR, ARMS, LEGS, BACK, RIGHT_HAND, LEFT_HAND }

var equipped_items = {
	SlotType.HEAD: null,
	SlotType.ARMOR: null,
	SlotType.ARMS: null,
	SlotType.LEGS: null,
	SlotType.BACK: null,
	SlotType.RIGHT_HAND: null,
	SlotType.LEFT_HAND: null
}

func equip(item: Equipment, slot: SlotType) -> bool:
	if equipped_items[slot] == null:
		equipped_items[slot] = item
		return true
	return false

func unequip(slot: SlotType) -> Equipment:
	var removed = equipped_items[slot]
	equipped_items[slot] = null
	return removed

func get_equipment(slot: SlotType) -> Equipment:
	return equipped_items[slot]

func print_equipment():
	for slot in equipped_items.keys():
		if equipped_items[slot]:
			print(slot, ":", equipped_items[slot].name)
