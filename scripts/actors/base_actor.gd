extends CharacterBody3D
class_name BaseActor
@onready var health_node = %Health

@onready var mesh_root: Node3D = %MeshRoot

#set this by each individual actor
var anim_tree: AnimationTree
const EquipmentSystem = preload("res://scripts/actors/equipment.gd")
const Inventory = preload("res://scenes/actors/inventory/inventory.gd")

@onready var remote_transform: RemoteTransform3D = %RemoteTransform
@onready var anim_controller: AnimationController = %AnimController
@onready var move_controller: MoveController = %MoveController
@onready var collider: CollisionShape3D = %Collider
@onready var equipment_system: EquipmentSystem = EquipmentSystem.new()
@onready var inventory: Inventory = Inventory.new()

var move_direction: Vector3: 
	get:
		var dir := Vector3.ZERO
		dir.x = _left_strength - _right_strength
		dir.z = _forward_strength - _back_strength
		if _jumped:
			dir.y = 1.0
		elif move_controller.actor_state() == ActorStateList.floating:
			dir.y = _up_strength - _down_strength
		elif not is_on_floor():
			dir.y = -1.0
		else:
			dir.y = 0.0
		return dir

var _right_strength: float = 0.0
var _left_strength: float = 0.0
var _forward_strength: float = 0.0
var _back_strength: float = 0.0
var _up_strength: float = 0.0
var _down_strength: float = 0.0
var _sprinting: bool = false
var _jumped: bool = false

#purely for convenience and brevity
var actor_state: ActorState:
	get:
		return move_controller.actor_state()

const _gravity_force: float = -9.81

func moving() -> bool:
	return abs(move_direction.x) > 0 or abs(move_direction.y) > 0 or abs(move_direction.z) > 0

func toggle_floating() -> void:
	if move_controller.actor_state() != ActorStateList.floating:
		move_controller.set_actor_state(ActorStateList.floating)
		motion_mode = MotionMode.MOTION_MODE_FLOATING
	else:
		move_controller.set_actor_state(ActorStateList.neutral)
		motion_mode = MotionMode.MOTION_MODE_GROUNDED

func toggle_crouching() -> void:
	if actor_state != ActorStateList.crouching and actor_state != ActorStateList.floating:
		move_controller.set_actor_state(ActorStateList.crouching)
		motion_mode = MotionMode.MOTION_MODE_GROUNDED
		if collider.shape:
			if collider.shape is CapsuleShape3D:
				var cap: CapsuleShape3D = collider.shape
				cap.height = cap.height / 2
				collider.position -= Vector3(0, cap.height / 2, 0)
				print(collider.position)
	else:
		move_controller.set_actor_state(ActorStateList.neutral)
		motion_mode = MotionMode.MOTION_MODE_GROUNDED
		if collider.shape:
			if collider.shape is CapsuleShape3D:
				var cap: CapsuleShape3D = collider.shape
				collider.position += Vector3(0, cap.height / 2, 0)
				print(collider.position)
				cap.height = cap.height * 2

func _on_health_changed(old: int, new: int):
	print("%s took damage - %s to %s" % [name, old, new])

func basic_movement(delta: float):
	if moving():
		move_controller.set_move_dir(move_direction)
		if _jumped:
			anim_controller.anim_tree["parameters/jump/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE
			if is_on_floor():
				velocity += Vector3(0, 5, 0)
				if actor_state == ActorStateList.crouching:
					toggle_crouching()
		else:
			if _sprinting:
				if move_controller.actor_state() != ActorStateList.floating:
					move_controller.set_move_state(MoveStateList.sprint)
			else:
				move_controller.set_move_state(MoveStateList.run)
	else:
		move_controller.set_move_state(MoveStateList.idle)

	var target_rotation: float = atan2(move_controller.direction.x, move_controller.direction.z) - rotation.y
	mesh_root.rotation.y = lerp_angle(mesh_root.rotation.y, target_rotation, move_controller.current_move_state.rotation_speed * delta)
	if move_controller.actor_state() != ActorStateList.floating:
		#if the state's grounded we need to ignore whatever the player wants to say about Y values, sans jumping
		#hilariously, as a result of this, the 'jump' state is actually grounded
		var vel_x: float = lerp(velocity.x, move_controller.get_desired_velocity().x, move_controller.move_state().acceleration * delta)
		var vel_z: float = lerp(velocity.z, move_controller.get_desired_velocity().z, move_controller.move_state().acceleration * delta)
		var vel_y: float = velocity.y + (_gravity_force * delta)
		#where 55 is terminal velocity
		velocity = Vector3(vel_x, vel_y, vel_z)
		
	else:
		velocity = velocity.lerp(move_controller.get_desired_velocity(), move_controller.current_move_state.acceleration * delta)
	_jumped = false
	move_and_slide()

func drop_equipment():
	for slot in equipment_system.equipped_items.keys():
		var item = equipment_system.unequip(slot)
		if item:
			print("Dropped Equipment:", item.name)

func drop_inventory():
	for row in inventory.grid:
		for cell in row:
			if cell.item:
				print("Dropped Item:", cell.item.name)
				cell.item = null

func show_inventory_debug():
	var display_text = "\n=== PLAYER INVENTORY & EQUIPMENT ===\n"

	display_text += "\n--- Equipped Items ---\n"
	var slot_names = {
		0: "Head",
		1: "Chest",
		2: "Arms",
		3: "Legs",
		4: "Back",
		5: "Primary Weapon",
		6: "Secondary Weapon"
	}

	for slot_id in slot_names.keys():
		var item = equipment_system.equipped_items.get(slot_id, null)
		display_text += slot_names[slot_id] + ": " + (item.name if item else "Empty") + "\n"

	display_text += "\n--- Inventory Items ---\n"
	var empty_slots = 3
	var item_count = 0


	for row in inventory.grid:
		for cell in row:
			if cell.item:
				display_text += "- " + cell.item.name + " (x" + str(cell.quantity) + ")\n"
				item_count += 1


	for i in range(empty_slots - item_count):
		display_text += "- Empty Slot\n"

	print(display_text)
	show_centered_text(display_text)


func show_centered_text(text: String):
	var label = Label.new()
	label.text = text
	label.set("theme_override_colors/font_color", Color(1, 1, 1))
	label.set("theme_override_font_sizes/font_size", 24)
	label.set_anchors_preset(Control.PRESET_CENTER)
	label.set_size(Vector2(600, 400))
	label.add_theme_color_override("font_color", Color(1, 1, 1))
	
	for child in get_tree().root.get_children():
		if child.name == "DebugInventoryUI":
			child.queue_free()

	var container = Control.new()
	container.name = "DebugInventoryUI"
	container.set_anchors_preset(Control.PRESET_CENTER)
	container.set_size(Vector2(600, 400))
	
	container.add_child(label)
	get_tree().root.add_child(container)


	get_tree().create_timer(5).timeout.connect(container.queue_free)

func _on_death():
	drop_equipment()
	drop_inventory()
