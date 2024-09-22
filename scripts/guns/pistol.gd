extends Node3D
class_name Weapon

@export var stats: WeaponStats
@export var firing: bool = false
@export var camera: Camera3D
@export var room_muffling = "close"
@export var reverb = "medium_room"




var _laser_fx := preload("res://scenes/fx/laser.tscn")

var _time_since_last_shot: float = 0.0
var _current_clip_count: int
var _time_reloading: float = 0.0
var sfx: FmodEventEmitter3D = null
var bank
func _ready():
	_current_clip_count = stats.max_clip
	if !stats.uses_ammo:
		_current_clip_count = 1
	#bank = FmodBankLoader.new()
	#bank.set_bank_paths(["bank:/Master.strings","bank:/Master","bank:/sfx/placeholder/weapon"])
	#self.add_child(bank)
	
	
func _physics_process(delta):
	
	#bullet logic
	while firing and _time_since_last_shot >= stats.firing_speed and _current_clip_count > 0:
		if stats.uses_ammo:
			_current_clip_count -= 1
		_time_since_last_shot -= stats.firing_speed
		print("Blam! Blam!")
		self.fire()
		#this should probably be its own class that handles instancing oneshot sfx, leaving it here for now as an example


		#raycast
		var space_state = get_world_3d().direct_space_state
		var mousepos = get_viewport().get_mouse_position()
		var origin = camera.project_ray_origin(mousepos)
		var end = origin + camera.project_ray_normal(mousepos) * stats.weapon_range
		var query = PhysicsRayQueryParameters3D.create(origin, end)
		query.collide_with_areas = true
		
		var result: Dictionary = space_state.intersect_ray(query)
		var hit_point: Vector3 = end
		if !result.is_empty():
			print("Hit something!")
			var collider: Node3D = result.collider
			hit_point = result.position
			if collider.has_node("%Health"):
				print("Hit something with a health node!")
				var hp: Health = collider.get_node("%Health")
				hp.damage(stats.damage)
				print(hp.current_health)
		else:
			print("Whiffed!")
		
		var laser: Laser = _laser_fx.instantiate()
		get_tree().current_scene.add_child(laser)
		laser.position = global_position
		laser.target_position = Vector3(0, stats.weapon_range, 0)
		laser.look_at(hit_point)
		laser.length = stats.weapon_range
		laser.beam_mesh.mesh.height = stats.weapon_range
		
	_time_since_last_shot += delta
	if _time_since_last_shot > stats.firing_speed:
		_time_since_last_shot = stats.firing_speed
	
	#reloading logic
	if _current_clip_count == 0:
		_time_reloading += delta
		print(_time_reloading)
		if _time_reloading >= stats.reload_time:
			_current_clip_count = stats.max_clip
			_time_reloading = 0.0
			print("Reloaded!")

func fire():
	#this will be changed, this is just so the audio actually plays
	sfx = FmodEventEmitter3D.new()
	sfx.set_attached(true)
	#sfx.global_transform = self.global_transform
	sfx.set_auto_release(true) #this deletes the node after it plays once
	sfx.set_autoplay(true)
	sfx.set_event_name("event:/sfx/players/weapons/placeholder_gun/placeholder_gun")
	sfx.set_parameter("room_muffling", room_muffling)
	sfx.set_parameter("reverb", reverb)
	self.add_child(sfx)
