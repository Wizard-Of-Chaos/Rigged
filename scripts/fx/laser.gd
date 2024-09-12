extends RayCast3D
@onready var beam_mesh = %BeamMesh

func _ready():
	pass

func _process(_delta):
	force_raycast_update()
	if is_colliding():
		var length: float = to_local(get_collision_point()).y
		beam_mesh.mesh.height = length
		beam_mesh.position.y = length / 2
