extends Node3D
class_name Weapon

@export var stats: WeaponStats
@export var firing: bool = false
@export var camera: Camera3D
@export var room_muffling = "close"
@export var reverb = "medium_room"
@onready var effect_node: Node = $EffectNode
@onready var gun_effect_spawner: MultiplayerSpawner = $GunSpawner

#var _laser_fx := preload("res://scenes/fx/laser.tscn")

var _time_since_last_shot: float = 0.0
var _current_clip_count: int
var _time_reloading: float = 0.0
var sfx: FmodEventEmitter3D = null
#sfx
#found the agonizing bug that this library doesn't properly update guids if you initialize events by the event name
#"event:/sfx/players/weapons/placeholder_gun/fire"

var _sfx_script := preload("res://scripts/audio/sound_handler_3d.gd")
var _fire_sfx = "event:/sfx/player/weapons/placeholder_gun/fire"
var _reload_sfx = "event:/sfx/player/weapons/placeholder_gun/reload"

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
		self.play_sfx(_fire_sfx)
		
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
				hp.damage.rpc_id(hp.get_multiplayer_authority(), stats.damage)
				# print(hp.current_health)
		else:
			print("Whiffed!")
		gun_effect_spawner.spawn([stats.weapon_range, global_position, hit_point])
	
	_time_since_last_shot += delta
	if _time_since_last_shot > stats.firing_speed:
		_time_since_last_shot = stats.firing_speed
	
	#reloading logic
	if _current_clip_count == 0:
		if _time_reloading == 0:
			self.play_sfx(_reload_sfx)
		_time_reloading += delta
		print(_time_reloading)
		if _time_reloading >= stats.reload_time:
			_current_clip_count = stats.max_clip
			_time_reloading = 0.0
			print("Reloaded!")

func play_sfx(event):
	sfx = FmodEventEmitter3D.new()
	sfx.set_script(_sfx_script)
	print(%FmodBankLoader.get_bank_paths())
	sfx.make_one_shot(event, {"room_muffling": room_muffling, "reverb": reverb}, true)
	self.add_child(sfx)
	sfx.play()
