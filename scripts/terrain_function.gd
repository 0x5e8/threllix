@tool
class_name TerrainFunction
extends Resource

signal function_changed

const EPSILON := 0.0001

func get_height(x: float, y: float) -> float:
	return 0

func get_normal(x: float, y: float) -> Vector3:
	return Vector3(
		(get_height(x + EPSILON, y) - get_height(x - EPSILON, y)) / (2 * EPSILON),
		1.0,
		(get_height(x, y + EPSILON) - get_height(x, y - EPSILON)) / (2 * EPSILON)
	).normalized()
