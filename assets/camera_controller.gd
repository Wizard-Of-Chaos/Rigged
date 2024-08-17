extends Node

@onready var yaw_node: Node3D = $CamYaw
@onready var pitch_node: Node3D = $CamYaw/CamPitch
@onready var camera: Camera3D = $CamYaw/CamPitch/SpringArm3D/Camera3D

@export var yaw_sensitivity: float = 0.07
@export var pitch_sensitivity: float = 0.07
@export var yaw_acceleration: float = 15
@export var pitch_acceleration: float = 15
@export var pitch_max: float = 75
@export var pitch_min: float = -55

var yaw: float = 0
var pitch: float = 0


# Called when the node enters the scene tree for the first time.
func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventMouseMotion:
		yaw += -event.relative.x * yaw_sensitivity
		pitch += -event.relative.y * pitch_sensitivity

func _physics_process(delta):
	pitch = clamp(pitch, pitch_min, pitch_max)
	#yaw = clamp(yaw, yaw_min, yaw_max)
	yaw_node.rotation_degrees.y = lerp(yaw_node.rotation_degrees.y, yaw, yaw_acceleration * delta)
	pitch_node.rotation_degrees.x = lerp(yaw_node.rotation_degrees.x, pitch, pitch_acceleration * delta)
