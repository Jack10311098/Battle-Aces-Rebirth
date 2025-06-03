extends CharacterBody3D

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		var camera = get_viewport().get_camera_3d()
		if camera:
			var from = camera.project_ray_origin(event.position)
			var to = from + camera.project_ray_normal(event.position) * 1000.0

			var query = PhysicsRayQueryParameters3D.new()
			query.from = from
			query.to = to
			query.exclude = [self]
			query.collide_with_areas = false
			query.collide_with_bodies = true

			var space_state = get_world_3d().direct_space_state
			var result = space_state.intersect_ray(query)

			if result:
				var clicked_point = result.position
				# Instantly teleport — only change X and Z, keep current Y
				global_position = Vector3(clicked_point.x, global_position.y, clicked_point.z)
