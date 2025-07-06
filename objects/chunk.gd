@tool
class_name Chunk
extends StaticBody3D

var size: float = 256.0:
	set(new):
		size = new
		update_pos()
@export var chunk_position: Vector2i:
	set(new):
		chunk_position = new
		update_pos()

func update_pos():
	var flat_pos = chunk_position * size
	position.x = flat_pos.x
	position.z = flat_pos.y

func update_mesh(resolution: int, amplitude: float, terrain_function: TerrainFunction) -> void:
	var plane := PlaneMesh.new()
	plane.subdivide_width = resolution
	plane.subdivide_depth = resolution
	plane.size = Vector2(size, size)
	
	var epsilon := size / float(resolution)
	
	var plane_arrays := plane.get_mesh_arrays()
	var vertex_array: PackedVector3Array = plane_arrays[ArrayMesh.ARRAY_VERTEX]
	var normal_array: PackedVector3Array = plane_arrays[ArrayMesh.ARRAY_NORMAL]
	var tangent_array: PackedFloat32Array = plane_arrays[ArrayMesh.ARRAY_TANGENT]
	
	for i: int in vertex_array.size():
		var vertex := vertex_array[i]
		var normal := Vector3.UP
		var tangent := Vector3.RIGHT
		if terrain_function:
			vertex.y = terrain_function.get_height(vertex.x + position.x, vertex.z + position.z) * amplitude
			normal = terrain_function.get_normal(vertex.x + position.x, vertex.z + position.z, amplitude, epsilon)
			tangent = normal.cross(Vector3.UP)
		vertex_array[i] = vertex
		normal_array[i] = normal
		tangent_array[4 * i + 0] = tangent.x
		tangent_array[4 * i + 1] = tangent.y
		tangent_array[4 * i + 2] = tangent.z
	
	var array_mesh := ArrayMesh.new()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, plane_arrays)
	%mesh.mesh = array_mesh
	%collision.shape = array_mesh.create_trimesh_shape()
