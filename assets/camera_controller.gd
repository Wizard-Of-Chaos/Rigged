extends Node3D
class_name CameraController

signal set_cam_rotation(_cam_rotation: float)

@onready var yaw_node: Node3D = $CamYaw
@onready var pitch_node: Node3D = $CamYaw/CamPitch
@onready var camera: Camera3D = $CamYaw/CamPitch/Camera3D
@onready var ik_target: Node3D = $CamYaw/CamPitch/IKTarget

@export var yaw_sensitivity: float = 0.07
@export var pitch_sensitivity: float = 0.07
@export var yaw_acceleration: float = 15
@export var pitch_acceleration: float = 15
@export var pitch_max: float = 75
@export var pitch_min: float = -55

var yaw: float = 0
var pitch: float = 0

var tween: Tween

# Called when the node enters the scene tree for the first time.
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_set_movestate(movestate: MoveState):
	if tween:
		tween.kill() #I FUCKING HATE PEOPLE AGED 10-12
	tween = create_tween() #BUT NOT ENOUGH TO STOP THEIR EXISTENCE
	tween.tween_property(camera, "fov", movestate.fov, .5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

func _input(event):
	if event is InputEventMouseMotion:
		yaw += -event.relative.x * yaw_sensitivity
		pitch += -event.relative.y * pitch_sensitivity

func _physics_process(delta):
	pitch = clamp(pitch, pitch_min, pitch_max)
	#yaw = clamp(yaw, yaw_min, yaw_max)
	yaw_node.rotation_degrees.y = lerp(yaw_node.rotation_degrees.y, yaw, yaw_acceleration * delta)
	pitch_node.rotation_degrees.x = lerp(yaw_node.rotation_degrees.x, pitch, pitch_acceleration * delta)
	
	set_cam_rotation.emit(yaw_node.rotation.y)
