extends Node

@export var player : CharacterBody3D
@export var mesh_root : Node3D
@export var rotation_speed : float = 8
var direction : Vector3
var velocity : Vector3
var acceleration : float
var speed : float
var cam_rotation : float = 0

func _on_set_movestate(_movestate : MoveState):
	speed = _movestate.speed
	acceleration = _movestate.acceleration

func _on_set_movedir(_movedir : Vector3):
	direction = _movedir.rotated(Vector3.UP, cam_rotation)

func _on_set_cam_rotation(_camrot : float):
	cam_rotation = _camrot

func _physics_process(delta):
	velocity.x = speed * direction.normalized().x
	velocity.z = speed * direction.normalized().z
	
	player.velocity = player.velocity.lerp(velocity, acceleration*delta)
	player.move_and_slide()
	
	var target_rotation = atan2(direction.x, direction.z) - player.rotation.y
	mesh_root.rotation.y = lerp_angle(mesh_root.rotation.y, target_rotation, rotation_speed * delta)
