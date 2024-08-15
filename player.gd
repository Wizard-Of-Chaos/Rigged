extends CharacterBody3D

@export var speed = 14
@export var fall_acceleration = 75

var target_velocity = Vector3.ZERO

func _physics_process(delta: float) -> void:
	var direction = Vector3.ZERO
	var movementData := Steam.getAnalogActionData(SteamGlobal.player_one, SteamGlobal.movementHandle)
	direction.x = -movementData["x"]
	direction.z = movementData["y"]
	if direction != Vector3.ZERO:
		direction = direction.normalized()
	target_velocity.x = direction.x * speed
	target_velocity.z = direction.z * speed
	
	if not is_on_floor():
		target_velocity.y = target_velocity.y - (fall_acceleration * delta)
	
	velocity = target_velocity
	move_and_slide()
