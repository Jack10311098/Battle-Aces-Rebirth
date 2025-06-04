extends Control

@export var camera: Camera3D
var selectable_units: Array = []

func _ready():
	mouse_filter = Control.MOUSE_FILTER_PASS
	add_to_group("selection_system")

func add_selectable_unit(unit):
	if not unit in selectable_units:
		selectable_units.append(unit)

func remove_selectable_unit(unit):
	if unit in selectable_units:
		selectable_units.erase(unit)

func clear_selection():
	for unit in selectable_units:
		unit.set_selected(false)

var drawing := false
var start_pos := Vector2.ZERO
var end_pos := Vector2.ZERO

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				drawing = true
				start_pos = event.position
				end_pos = event.position
				
				if not Input.is_key_pressed(KEY_SHIFT) and (end_pos - start_pos).length() < 5:
					clear_selection()
			else:
				drawing = false
				select_units_in_rect()
				queue_redraw()
				
		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			var target_pos = get_ground_position(event.position)
			if target_pos != Vector3.ZERO:  # Valid position found
				if Input.is_key_pressed(KEY_SHIFT):
					# Queue movement command
					for unit in selectable_units:
						if unit.selected and unit.has_method("queue_move_to"):
							unit.queue_move_to(target_pos)
				else:
					# Immediate movement command
					for unit in selectable_units:
						if unit.selected and unit.has_method("move_to"):
							unit.move_to(target_pos)
					
	elif event is InputEventMouseMotion and drawing:
		end_pos = event.position
		queue_redraw()

func get_ground_position(screen_pos: Vector2) -> Vector3:
	var viewport = get_viewport()
	if not viewport:
		return Vector3.ZERO
		
	var cam = viewport.get_camera_3d()
	if not cam:
		return Vector3.ZERO
		
	var from = cam.project_ray_origin(screen_pos)
	var to = from + cam.project_ray_normal(screen_pos) * 1000.0
	var space_state = viewport.world_3d.direct_space_state
	var query = PhysicsRayQueryParameters3D.create(from, to)
	var result = space_state.intersect_ray(query)
	
	return result.position if result else Vector3.ZERO

func _draw():
	if drawing:
		var rect = Rect2(start_pos, end_pos - start_pos).abs()
		draw_rect(rect, Color(0, 1, 0, 0.2), true)
		draw_rect(rect, Color(0, 1, 0), false, 2)

func select_units_in_rect():
	var rect = Rect2(start_pos, end_pos - start_pos).abs()
	var selection_made = false
	var is_shift_held = Input.is_key_pressed(KEY_SHIFT)
	
	for unit in selectable_units:
		if not is_instance_valid(unit):
			continue
			
		var screen_pos = camera.unproject_position(unit.global_position)
		if not screen_pos:  # Skip if unit is behind camera
			continue
			
		var unit_rect = Rect2(screen_pos - Vector2(20, 20), Vector2(40, 40))
		if rect.intersects(unit_rect, true):
			if is_shift_held:
				if not unit.selected:
					unit.set_selected(true)
					selection_made = true
			else:
				if not unit.selected:
					unit.set_selected(true)
					selection_made = true
	
	if not is_shift_held and not selection_made and (end_pos - start_pos).length() > 5:
		clear_selection()
