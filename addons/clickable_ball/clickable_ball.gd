@tool
extends Area3D
class_name ClickableBall

@onready var mesh: MeshInstance3D = %MeshInstance3D

signal clicked


func set_color(color: Color):
	if not mesh.material_override:
		mesh.material_override = mesh.mesh.surface_get_material(0).duplicate()
	var mat := mesh.material_override
	mat.albedo_color = color
