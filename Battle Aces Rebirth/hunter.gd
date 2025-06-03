extends CharacterBody3D

@export var speed := 10.0
@export var accel := 10.0
@onready var nav: NavigationAgent3D = $NavigationAgent3D
@onready var anim: AnimationPlayer = $AnimationPlayer

var selected = false

func _ready():
	# Add this unit to the selection system when it spawns
	var selection_system = get_tree().get_first_node_in_group("selection_system")
	if selection_system:
		selection_system.add_selectable_unit(self)

func set_selected(value):
	selected = value
	if has_node("SelectionIndicator"):
		$SelectionIndicator.visible = selected

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		if not selected:
			return  # Only selected units respond to right-click
			
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
				# Set navigation target instead of teleporting
				nav.target_position = Vector3(clicked_point.x, global_position.y, clicked_point.z)

func _physics_process(delta):
	var direction = nav.get_next_path_position() - global_position
	direction.y = 0

	if direction.length() > 0.1:
		direction = direction.normalized()
		velocity = velocity.lerp(direction * speed, accel * delta)
		move_and_slide()

		# Smoothly rotate toward movement direction
		var current_dir = -transform.basis.z
		var new_dir = current_dir.slerp(direction, 10.0 * delta).normalized()
		look_at(global_position + new_dir, Vector3.UP)
	else:
		velocity = Vector3.ZERO

	# Play walk animation with speed based on movement velocity
	anim.play("walk")
	var move_speed = velocity.length()
	anim.speed_scale = clamp(move_speed / speed * 3.0, 1.0, 3.0)
