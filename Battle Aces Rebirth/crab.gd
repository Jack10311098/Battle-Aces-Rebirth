extends CharacterBody3D

@export var speed := 15.0
@export var accel := 10.0
@onready var nav: NavigationAgent3D = $NavigationAgent3D
@onready var anim: AnimationPlayer = $AnimationPlayer

var selected = false
var debug_line: ImmediateMesh
var debug_mesh_instance: MeshInstance3D

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
	if selected and nav.target_position != Vector3.ZERO:
		debug_line.clear_surfaces()
		debug_line.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
		var start_pos = Vector3.ZERO
		var end_pos = to_local(nav.target_position)
		start_pos.y = 0.1
		end_pos.y = 0.1
		debug_line.surface_add_vertex(start_pos)
		debug_line.surface_add_vertex(end_pos)
		debug_line.surface_end()

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
			nav.target_position = Vector3(result.position.x, global_position.y, result.position.z)

func _physics_process(delta):
	var direction = nav.get_next_path_position() - global_position
	direction.y = 0

	if direction.length() > 0.1:
		direction = direction.normalized()
		velocity = velocity.lerp(direction * speed, accel * delta)
		move_and_slide()

		var current_dir = -transform.basis.z
		var new_dir = current_dir.slerp(direction, 10.0 * delta).normalized()
		look_at(global_position + new_dir, Vector3.UP)
	else:
		velocity = Vector3.ZERO

	anim.play("walk")
	var move_speed = velocity.length()
	anim.speed_scale = clamp(move_speed / speed * 3.0, 1.0, 3.0)
