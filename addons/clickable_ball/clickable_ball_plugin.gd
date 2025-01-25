@tool
extends EditorPlugin


func _enter_tree() -> void:
	# Initialization of the plugin goes here.
	set_input_event_forwarding_always_enabled()

func _forward_3d_gui_input(viewport_camera: Camera3D, event: InputEvent) -> int:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		var origin := viewport_camera.project_ray_origin(event.position)
		var end := origin + viewport_camera.project_ray_normal(event.position) * viewport_camera.far
		var query := PhysicsRayQueryParameters3D.create(origin, end, 1 << 30)
		query.collide_with_areas = true
		var result := viewport_camera.get_world_3d().direct_space_state.intersect_ray(query)
		if result and result.collider is ClickableBall:
			if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
				result.collider.clicked.emit()
				return EditorPlugin.AFTER_GUI_INPUT_STOP
			#elif event is InputEventMouseMotion:
				#var mat: StandardMaterial3D = hit.collider.mesh.get_surface_override_material(0)
				#mat.emission_energy_multiplier = 4.0
	return EditorPlugin.AFTER_GUI_INPUT_PASS
