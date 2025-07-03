@tool
class_name NoiseTerrain
extends TerrainFunction

@export var noise: FastNoiseLite:
	set(new):
		noise = new
		if noise:
			noise.changed.connect(function_changed.emit)

func get_height(x: float, y: float) -> float:
	return noise.get_noise_2d(x, y)
