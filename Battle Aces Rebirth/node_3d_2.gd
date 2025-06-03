extends Node3D

@onready var camera: Camera3D = $Camera3D

@export var pan_speed: float = 30.0
@export var edge_threshold: int = 50            # pixels from screen edge to start panning
@export var counter_angle_deg: float = -36.3    # rotate input direction to counter camera rotation

func _physics_process(delta: float) -> void:
	# Get mouse position and viewport size
	var mouse_pos = get_viewport().get_mouse_position()
	var screen_size = get_viewport().get_visible_rect().size

	var move_dir = Vector2.ZERO

	# Detect if mouse is near screen edges
	if mouse_pos.x <= edge_threshold:
		move_dir.x -= 1
	elif mouse_pos.x >= screen_size.x - edge_threshold:
		move_dir.x += 1

	if mouse_pos.y <= edge_threshold:
		move_dir.y -= 1
	elif mouse_pos.y >= screen_size.y - edge_threshold:
		move_dir.y += 1

	if move_dir != Vector2.ZERO:
		move_dir = move_dir.normalized()
		var angle_rad = deg_to_rad(counter_angle_deg)
		var corrected_dir = Vector2(
			move_dir.x * cos(angle_rad) - move_dir.y * sin(angle_rad),
			move_dir.x * sin(angle_rad) + move_dir.y * cos(angle_rad)
		)

		global_position.x += corrected_dir.x * pan_speed * delta
		global_position.z += corrected_dir.y * pan_speed * delta
