extends CharacterBody3D

@export var speed := 10.0
@export var accel := 10.0
@onready var nav: NavigationAgent3D = $NavigationAgent3D
@onready var anim: AnimationPlayer = $AnimationPlayer

var selected = false
var debug_line: ImmediateMesh
var debug_mesh_instance: MeshInstance3D
var movement_queue: Array = []  # Stores queued movement positions

# New variables for smooth navigation
var smooth_direction = Vector3.ZERO
var last_valid_direction = Vector3.FORWARD
var look_ahead_distance = 1.0  # How far ahead to look for smoother turns

func _ready():
	# Setup debug visualization
	debug_line = ImmediateMesh.new()
	debug_line.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	debug_line.surface_end()
	
	debug_mesh_instance = MeshInstance3D.new()
	debug_mesh_instance.mesh = debug_line
	debug_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(debug_mesh_instance)
	
	debug_mesh_instance.position = Vector3.ZERO
	debug_mesh_instance.rotation = Vector3.ZERO
	
	var material = StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0, 1, 0, 0.5)
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.flags_no_depth_test = true
	material.line_width = 5.0
	debug_mesh_instance.material_override = material
	
	debug_mesh_instance.visible = false
	
	var selection_system = get_tree().get_first_node_in_group("selection_system")
	if selection_system:
		selection_system.add_selectable_unit(self)

func set_selected(value):
	selected = value
	if has_node("SelectionIndicator"):
		$SelectionIndicator.visible = selected
	debug_mesh_instance.visible = selected
	if not selected:
		debug_line.clear_surfaces()
		debug_line.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
		debug_line.surface_end()

func _input_event(_camera, event, _position, _normal, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var selection_system = get_tree().get_first_node_in_group("selection_system")
		if selection_system:
			if Input.is_key_pressed(KEY_SHIFT):
				set_selected(!selected)
			else:
				selection_system.clear_selection()
				set_selected(true)

func _process(_delta):
	if selected:
		debug_line.clear_surfaces()
		debug_line.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
		
		# Draw current path
		if nav.target_position != Vector3.ZERO:
			var start_pos = Vector3.ZERO
			var end_pos = to_local(nav.target_position)
			start_pos.y = 0.1
			end_pos.y = 0.1
			debug_line.surface_add_vertex(start_pos)
			debug_line.surface_add_vertex(end_pos)
		
		# Draw queued paths
		for i in range(movement_queue.size()):
			var pos = to_local(movement_queue[i])
			pos.y = 0.1
			debug_line.surface_add_vertex(pos)
			if i > 0:
				debug_line.surface_add_vertex(pos)
		
		debug_line.surface_end()

func move_to(target_pos: Vector3):
	movement_queue.clear()
	nav.target_position = Vector3(target_pos.x, global_position.y, target_pos.z)

func queue_move_to(target_pos: Vector3):
	movement_queue.append(Vector3(target_pos.x, global_position.y, target_pos.z))
	if movement_queue.size() == 1:
		nav.target_position = movement_queue[0]

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		if not selected:
			return
			
		var viewport = get_viewport()
		if not viewport:
			return
			
		var camera = viewport.get_camera_3d()
		if not camera:
			return
			
		var from = camera.project_ray_origin(event.position)
		var to = from + camera.project_ray_normal(event.position) * 1000.0
		var space_state = viewport.world_3d.direct_space_state
		
		var query = PhysicsRayQueryParameters3D.create(from, to)
		query.exclude = [self]
		query.collide_with_areas = false
		query.collide_with_bodies = true
		
		var result = space_state.intersect_ray(query)
		if result:
			if Input.is_key_pressed(KEY_SHIFT):
				queue_move_to(result.position)
			else:
				move_to(result.position)

func _physics_process(delta):
	# Stop if very close to target
	if nav.target_position != Vector3.ZERO and global_position.distance_to(nav.target_position) < 0.3:
		velocity = Vector3.ZERO
		
		# Process movement queue
		if movement_queue.size() > 0:
			movement_queue.pop_front()
			if movement_queue.size() > 0:
				nav.target_position = movement_queue[0]
			else:
				nav.target_position = Vector3.ZERO
		return
	
	# Get next path positions
	var immediate_target = nav.get_next_path_position()
	var look_ahead_target = nav.get_next_path_position()
	
	# Calculate direction with look-ahead
	var raw_direction = (look_ahead_target - global_position)
	raw_direction.y = 0
	
	if raw_direction.length() > 0.1:
		smooth_direction = smooth_direction.lerp(raw_direction.normalized(), 5.0 * delta)
		last_valid_direction = smooth_direction.normalized()
	else:
		smooth_direction = last_valid_direction

	# Movement handling
	if smooth_direction.length() > 0.1:
		var immediate_dir = (immediate_target - global_position).normalized()
		velocity = velocity.lerp(immediate_dir * speed, accel * delta)
		move_and_slide()
		
		# Rotation handling
		if velocity.length() > 0.5:
			var look_position = global_position + smooth_direction
			look_at(look_position, Vector3.UP)
			var forward = -transform.basis.z
			if forward.dot(smooth_direction) < 0:
				rotate_y(PI)
	else:
		velocity = Vector3.ZERO

	# Animation handling - always play walk but scale speed to simulate stopping
	anim.play("walk")
	var move_speed = velocity.length()
	# Scale from 0.5 (stopped) to 3.0 (full speed)
	anim.speed_scale = clamp(0.5 + (move_speed / speed) * 2.5, 0.5, 3.0)
