class_name CameraController
extends Node3D

signal set_cam_rotation(_cam_rotation: float)

@onready var yaw_node: Node3D = $CamYaw
@onready var pitch_node: Node3D = $CamYaw/CamPitch
@onready var camera: Camera3D = $CamYaw/CamPitch/Camera3D
@onready var remote_transform: RemoteTransform3D = $CamYaw/CamPitch/RemoteTransform3D
@onready var crosshair: CenterContainer = $CamYaw/CamPitch/Camera3D/Crosshair
@onready var aim_ray: RayCast3D = $CamYaw/CamPitch/Camera3D/AimRay
@onready var ui_scene := preload("res://scenes/utilities/game_ui.tscn")
@export var yaw_sensitivity: float = 0.07
@export var pitch_sensitivity: float = 0.07
@export var yaw_acceleration: float = 15
@export var pitch_acceleration: float = 15
@export var pitch_max: float = 75
@export var pitch_min: float = -55

var yaw: float = 0
var pitch: float = 0

var move_tween: Tween
var player_tween: Tween

var devices: Array[int] = []


func _ready():
	if 0 in devices:
		print("This camera belongs to the mouse player")
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	crosshair.visible = false

	# Instance the UI and add it to the camera's view
	var ui_instance = ui_scene.instantiate()
	camera.add_child(ui_instance)  # Add the UI to the camera so it's superimposed

func _on_set_move_state(move_state: MoveState):
	if move_tween:
		move_tween.kill() #I FUCKING HATE PEOPLE AGED 10-12
	move_tween = create_tween() #BUT NOT ENOUGH TO STOP THEIR EXISTENCE
	move_tween.tween_property(camera, "fov", move_state.fov, .5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _on_set_actor_state(actor_state: ActorStateChange):
	if actor_state.new_state == actor_state.old_state:
		return
	if player_tween:
		player_tween.kill()
	player_tween = create_tween()
	if actor_state.old_state == ActorStateList.weapon_equipped and actor_state.new_state == ActorStateList.weapon_aiming:
		player_tween.tween_property(camera, "position", camera.position + Vector3(0, 0, -.75), .1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		#player_tween.parallel().tween_property(camera, "fov", camera.fov - 60, .1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	elif actor_state.old_state == ActorStateList.weapon_aiming:
		player_tween.tween_property(camera, "position", camera.position + Vector3(0, 0, .75), .1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		#player_tween.parallel().tween_property(camera, "fov", camera.fov + 60, .1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	else:
		player_tween.kill()
		printerr("Unknown state combo [%s, %s]" % [actor_state.old_state.name, actor_state.new_state.name])


func cam_input(event: InputEventMouseMotion) -> void:
	yaw += -event.relative.x * yaw_sensitivity
	pitch += -event.relative.y * pitch_sensitivity 


func _physics_process(delta: float) -> void:
	pitch = clamp(pitch, pitch_min, pitch_max)
	yaw_node.rotation_degrees.y = lerp(yaw_node.rotation_degrees.y, yaw, yaw_acceleration * delta)
	pitch_node.rotation_degrees.x = lerp(yaw_node.rotation_degrees.x, pitch, pitch_acceleration * delta)
	set_cam_rotation.emit(yaw_node.rotation.y)
