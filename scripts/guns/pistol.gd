extends Node3D
class_name Weapon

@export var stats: WeaponStats
@export var firing: bool = false
var _time_since_last_shot: float = 0.0
var _current_clip_count: int
var _time_reloading: float = 0.0

func _ready():
	_current_clip_count = stats.max_clip
	if !stats.uses_ammo:
		_current_clip_count = 1
	
func _physics_process(delta):
	while firing and _time_since_last_shot >= stats.firing_speed and _current_clip_count > 0:
		if stats.uses_ammo:
			_current_clip_count -= 1
		print("Blam! Blam!")
		_time_since_last_shot -= stats.firing_speed
		#raycast
		
	_time_since_last_shot += delta

func _process(delta):
	if _current_clip_count == 0:
		_time_reloading += delta
		print(_time_reloading)
		if _time_reloading >= stats.reload_time:
			_current_clip_count = stats.max_clip
			_time_reloading = 0.0
			print("Reloaded!")
	pass
