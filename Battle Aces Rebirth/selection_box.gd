# SelectionSystem script (extends Control)
extends Control

@export var camera: Camera3D
var selectable_units: Array = []  # Will be populated dynamically

func _ready():
	mouse_filter = Control.MOUSE_FILTER_PASS  # Receive mouse input
	add_to_group("selection_system")  # Allow units to find this system

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
				# Start selection box
				drawing = true
				start_pos = event.position
				end_pos = event.position
				
				# Clear selection if not holding shift
				if not Input.is_key_pressed(KEY_SHIFT):
					clear_selection()
			else:
				# Finish selection box
				drawing = false
				select_units_in_rect()
				queue_redraw()
				
		elif event.button_index == MOUSE_BUTTON_RIGHT and Input.is_key_pressed(KEY_SHIFT):
			# Right-click to deselect
			for unit in selectable_units:
				if unit.selected:
					unit.set_selected(false)
					
	elif event is InputEventMouseMotion and drawing:
		end_pos = event.position
		queue_redraw()

func _draw():
	if drawing:
		var rect = Rect2(start_pos, end_pos - start_pos).abs()
		draw_rect(rect, Color(0, 1, 0, 0.2), true)
		draw_rect(rect, Color(0, 1, 0), false, 2)

func select_units_in_rect():
	var rect = Rect2(start_pos, end_pos - start_pos).abs()
	
	for unit in selectable_units:
		if not is_instance_valid(unit):
			continue
			
		# Convert the unit's global position to screen coordinates
		var screen_pos = camera.unproject_position(unit.global_position)
		if rect.has_point(screen_pos):
			unit.set_selected(true)
