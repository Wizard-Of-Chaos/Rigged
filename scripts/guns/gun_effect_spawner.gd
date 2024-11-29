extends MultiplayerSpawner
var _laser_fx := preload("res://scenes/fx/laser.tscn")

func _ready():
	self.spawn_function = build_laser
	
func build_laser(args: Array):
	var stats: WeaponStats = args[0]
	var global_position: Vector3 = args[1]
	var hit_point: Vector3 = args[2]
	var laser: Laser = _laser_fx.instantiate()
	laser.wep_stats = stats
	laser.length = stats.weapon_range
	# laser.beam_mesh.mesh.height = stats.weapon_range
	laser.target_position = Vector3(0, stats.weapon_range, 0)
	laser.wep_stats = stats
	laser.position = global_position
	laser.look_at_from_position(global_position, hit_point)
	return laser
