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
				
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			if Input.is_key_pressed(KEY_SHIFT):
				if not is_issuing_movement_command(event):
					for unit in selectable_units:
						if unit.selected:
							unit.set_selected(false)
					
	elif event is InputEventMouseMotion and drawing:
		end_pos = event.position
		queue_redraw()

func is_issuing_movement_command(event: InputEventMouseButton) -> bool:
	if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		var viewport = get_viewport()
		if not viewport:
			return false
			
		var cam = viewport.get_camera_3d()
		if not cam:
			return false
			
		var from = cam.project_ray_origin(event.position)
		var to = from + cam.project_ray_normal(event.position) * 1000.0
		var space_state = viewport.world_3d.direct_space_state
		var query = PhysicsRayQueryParameters3D.create(from, to)
		return space_state.intersect_ray(query) != null
	return false

func _draw():
	if drawing:
		var rect = Rect2(start_pos, end_pos - start_pos).abs()
		draw_rect(rect, Color(0, 1, 0, 0.2), true)
		draw_rect(rect, Color(0, 1, 0), false, 2)

func select_units_in_rect():
	var rect = Rect2(start_pos, end_pos - start_pos).abs()
	var selection_made = false
	
	for unit in selectable_units:
		if not is_instance_valid(unit):
			continue
			
		var screen_pos = camera.unproject_position(unit.global_position)
		var unit_rect = Rect2(screen_pos - Vector2(20, 20), Vector2(40, 40))
		if rect.intersects(unit_rect, true):
			if Input.is_key_pressed(KEY_SHIFT):
				unit.set_selected(!unit.selected)
			else:
				unit.set_selected(true)
			selection_made = true
	
	if Input.is_key_pressed(KEY_SHIFT) and not selection_made:
		clear_selection()
