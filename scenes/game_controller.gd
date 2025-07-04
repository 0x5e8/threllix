@tool
extends Node

@onready var chunk_scene = preload("res://objects/chunk.tscn")

@export var player: CharacterBody3D

var current_chunk_pos := Vector2i.ZERO
var stored_chunk_pos := Vector2i.ZERO
var visible_chunks: Array[Chunk] = []
var chunk_map: Dictionary = {}

@export_range(1, 16, 1) var render_distance: int = 2:
	set(new): 
		render_distance = new
		update_visible_chunks()

@export var chunk_size := 256.0:
	set(new):
		chunk_size = new
		for chunk in visible_chunks:
			chunk.size = chunk_size
		update_visible_chunks()

@export_range(1, 32, 1) var chunk_resolution := 16:
	set(new):
		chunk_resolution = new
		update_terrain()

@export var chunk_amplitude: float = 5.3:
	set(new):
		chunk_amplitude = new
		update_terrain()

@export var terrain_function: TerrainFunction:
	set(new):
		terrain_function = new
		if terrain_function:
			terrain_function.changed.connect(update_terrain)

func _ready() -> void:
	update_visible_chunks()

func _process(delta: float) -> void:
	current_chunk_pos = get_chunk_position(player.position)
	if current_chunk_pos != stored_chunk_pos:
		move_chunks()
		stored_chunk_pos = current_chunk_pos

func update_visible_chunks():
	if not player:
		return
	
	# clear existed chunks
	for child in visible_chunks:
		remove_child(child)
		child.queue_free()
	visible_chunks.clear()
	chunk_map.clear()
	
	# generate points inside a circle
	var valid_points: Array[Vector2i] = []
	for y in range(-render_distance, render_distance + 1):
		var max_x = int(floor(sqrt(render_distance * render_distance - y * y)))
		for x in range(-max_x, max_x + 1):
			valid_points.append(Vector2i(x, y) + get_chunk_position(player.position))
	
	# then create as many chunks and assign those position to them
	for pos in valid_points:
		var new_chunk: Chunk = chunk_scene.instantiate()
		add_child(new_chunk)
		new_chunk.size = chunk_size
		new_chunk.chunk_position = pos
		new_chunk.update_mesh(chunk_resolution, chunk_amplitude, terrain_function)
		visible_chunks.append(new_chunk)
		chunk_map[pos] = new_chunk

func move_chunks():
	# BUG:
	# try move too fast and see chunks flying around
	
	# if player moves too fast then just move all the chunks
	var diff = current_chunk_pos - stored_chunk_pos
	if diff.length_squared() > 4 * render_distance * render_distance:
		update_visible_chunks()
		return
	
	# find all non overlap and new points of the 2 circles
	var old_points = chunk_map.keys()
	var new_points: Array[Vector2i] = []
	for y in range(-render_distance, render_distance + 1):
		var max_x = int(floor(sqrt(render_distance * render_distance - y * y)))
		for x in range(-max_x, max_x + 1):
			var pos = Vector2i(x, y) + current_chunk_pos
			
			if not chunk_map.has(pos):
				new_points.append(pos)
			else:
				# remove overlapping points from the old array
				# eventually we will get an array of old points
				# that not inside the new circle
				old_points.erase(pos)
	
	# now use all existed chunks that is not overlapping to fill in new space
	# and ONLY UPDATE these chunks
	for pos in old_points:
		var chunk: Chunk = chunk_map[pos]
		var new_point = new_points.back()
		new_points.pop_back()
		
		chunk_map.erase(pos)
		chunk_map[pos] = chunk
		chunk.chunk_position = new_point
		chunk.update_mesh(chunk_resolution, chunk_amplitude, terrain_function)

func update_terrain():
	for child: Chunk in visible_chunks:
		child.update_mesh(chunk_resolution, chunk_amplitude, terrain_function)

func get_chunk_position(pos: Vector3) -> Vector2i:
	# convert world pos to chunk pos
	var d = Vector2(chunk_size, chunk_size) / 2
	if pos.x < 0:
		d.x *= -1
	if pos.z < 0:
		d.y *= -1
	return (Vector2(pos.x, pos.z) + d) / chunk_size
