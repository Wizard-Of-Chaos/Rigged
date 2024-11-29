extends RayCast3D
class_name Laser
@onready var beam_mesh = %BeamMesh
@onready var end_particles = %EndParticles
var max_lifetime: float = 0.75
var current_lifetime: float = 0.0
var length: float = 0.0
var range: float

func _ready():
	beam_mesh.mesh.height = range

func we_are_in_the_beam(start: Vector3, end: Vector3):
	position = start
	target_position = end

func _process(delta):
	force_raycast_update()
	
	#if is_colliding():
		#var point: Vector3 = to_local(get_collision_point())
		#var length: float = point.y
		#beam_mesh.mesh.height = length
		#beam_mesh.position.y = length / 2
	current_lifetime += delta
	if(current_lifetime >= max_lifetime):
		if get_multiplayer_authority() == multiplayer.get_unique_id():
			queue_free()
		return
	
	beam_mesh.mesh.height = length * (1 - (current_lifetime / max_lifetime))
	beam_mesh.position.z = -length + beam_mesh.mesh.height/2
	#if is_colliding():
		#var point: Vector3 = to_local(get_collision_point())
		#var length: float = point.y
		#beam_mesh.mesh.height = length
		#beam_mesh.position.y = length / 2
		#end_particles.position.y = point.y
