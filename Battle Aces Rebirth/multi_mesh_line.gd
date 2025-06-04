extends MultiMeshInstance3D

class_name MultiMeshLineSystem

const LINE_COLOR = Color(1, 0.5, 0)  # Orange
const LINE_HEIGHT_OFFSET = 0.1

var unit_instances = {}  # unit: instance_id
var instance_positions = []  # [start1, end1, start2, end2,...]
var dirty = false

func _ready():
	# Setup multimesh
	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = create_line_mesh()
	add_to_group("line_system")

func create_line_mesh() -> Mesh:
	var mesh = ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	mesh.surface_add_vertex(Vector3.ZERO)
	mesh.surface_add_vertex(Vector3.FORWARD)
	mesh.surface_end()
	
	var material = StandardMaterial3D.new()
	material.albedo_color = LINE_COLOR
	material.shading_mode = StandardMaterial3D.SHADING_MODE_UNSHADED
	material.flags_no_depth_test = true
	mesh.surface_set_material(0, material)
	
	return mesh

func register_unit(unit) -> int:
	var instance_id = len(unit_instances)
	unit_instances[unit] = instance_id
	instance_positions.resize((instance_id + 1) * 2)
	multimesh.instance_count = len(unit_instances)
	return instance_id

func update_line(instance_id: int, start_pos: Vector3, end_pos: Vector3):
	start_pos.y += LINE_HEIGHT_OFFSET
	end_pos.y += LINE_HEIGHT_OFFSET
	
	instance_positions[instance_id * 2] = start_pos
	instance_positions[instance_id * 2 + 1] = end_pos
	dirty = true

func hide_line(instance_id: int):
	instance_positions[instance_id * 2] = Vector3.ZERO
	instance_positions[instance_id * 2 + 1] = Vector3.ZERO
	dirty = true

func _process(_delta):
	if dirty:
		update_multimesh()
		dirty = false

func update_multimesh():
	for i in range(len(unit_instances)):
		var start = instance_positions[i * 2]
		var end = instance_positions[i * 2 + 1]
		
		# Calculate transform (position is midpoint, basis points toward end)
		var midpoint = (start + end) / 2.0
		var direction = (end - start).normalized()
		var length = start.distance_to(end)
		
		var transform = Transform3D()
		transform = transform.looking_at(direction, Vector3.UP)
		transform = transform.scaled(Vector3(1, 1, length))
		transform.origin = midpoint
		
		multimesh.set_instance_transform(i, transform)
