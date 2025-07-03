@tool
extends StaticBody3D

const size := 256.0

@export_range(1, 256, 1) var resolution := 4:
	set(new_res):
		resolution = new_res
		update_mesh()

@export var amplitude: float = 5.3:
	set(new_amp):
		amplitude = new_amp
		update_mesh()

@export var terrain_function: TerrainFunction:
	set(new_func):
		terrain_function = new_func
		update_mesh()
		if terrain_function:
			terrain_function.function_changed.connect(update_mesh)

func update_mesh() -> void:
	var plane := PlaneMesh.new()
	plane.subdivide_width = resolution
	plane.subdivide_depth = resolution
	plane.size = Vector2(size, size)
	
	var plane_arrays := plane.get_mesh_arrays()
	var vertex_array: PackedVector3Array = plane_arrays[ArrayMesh.ARRAY_VERTEX]
	var normal_array: PackedVector3Array = plane_arrays[ArrayMesh.ARRAY_NORMAL]
	var tangent_array: PackedFloat32Array = plane_arrays[ArrayMesh.ARRAY_TANGENT]
	
	for i: int in vertex_array.size():
		var vertex := vertex_array[i]
		var normal := Vector3.UP
		var tangent := Vector3.RIGHT
		if terrain_function:
			vertex.y = terrain_function.get_height(vertex.x, vertex.z) * amplitude
			normal = terrain_function.get_normal(vertex.x, vertex.z)
			tangent = normal.cross(Vector3.UP)
		vertex_array[i] = vertex
		normal_array[i] = normal
		tangent_array[4 * i + 0] = tangent.x
		tangent_array[4 * i + 1] = tangent.y
		tangent_array[4 * i + 2] = tangent.z
	
	var array_mesh := ArrayMesh.new()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, plane_arrays)
	$mesh.mesh = array_mesh
	
	$collision.shape = array_mesh.create_trimesh_shape()
