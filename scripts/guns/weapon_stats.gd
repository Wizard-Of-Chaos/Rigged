extends Resource
class_name WeaponStats

@export var id: int
@export var name: String
@export var firing_speed: float
@export var damage: int
@export var weapon_range: float = 20
@export var hitscan: bool = true
@export var projectile_speed: float = 1000
@export var two_handed: bool = false
@export var uses_ammo: bool = true
@export var reload_time: float
@export var max_clip: int