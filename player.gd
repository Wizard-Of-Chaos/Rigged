extends CharacterBody3D

@export var speed: float = 14
@export var fall_acceleration: float = 75
@export var jump_impulse: float = 40

var target_velocity := Vector3.ZERO

func _physics_process(delta: float) -> void:
	var direction := Vector3.ZERO
	var movementData := Steam.getAnalogActionData(SteamGlobal.player_one, SteamGlobal.movementHandle)
	var jumpData := Steam.getDigitalActionData(SteamGlobal.player_one, SteamGlobal.jumpHandle)
	direction.x = -movementData.x
	direction.z = movementData.y
	if direction != Vector3.ZERO:
		direction = direction.normalized()
	target_velocity.x = direction.x * speed
	target_velocity.z = direction.z * speed
	
	if not is_on_floor():
		target_velocity.y = target_velocity.y - (fall_acceleration * delta)
	elif jumpData.state:
		target_velocity.y = jump_impulse
	
	velocity = target_velocity
	move_and_slide()
