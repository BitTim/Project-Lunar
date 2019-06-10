extends Node2D

export(Vector2) var max_map_size
export(Vector2) var chunk_size
export(Vector2) var chunks_per_screen
export(int) var map_seed = randi()
export(int) var num_max_craters_per_chunk = 1
export(int) var num_tiles
export(int) var num_resources
export(float) var resource_threshold

var tile_size
var checked_positions = []
onready var chunk_x_offsets = [-chunk_size.x, 0, chunk_size.x, -chunk_size.x, 0, chunk_size.x, -chunk_size.x, 0, chunk_size.x]
onready var chunk_y_offsets = [-chunk_size.y, -chunk_size.y, -chunk_size.y, 0, 0, 0, chunk_size.y, chunk_size.y, chunk_size.y]

func _ready():
	tile_size = $Ground.cell_size
	randomize()
	map_seed = randi()
	_init_player()
	
	for i in range(0, 9):
		_generate_chunk(chunk_size, Vector2(($Player.position.x / tile_size.x) + chunk_x_offsets[i], ($Player.position.y / tile_size.y) + chunk_y_offsets[i]))
	
	_set_camera_limits()

func _init_player():
	$Player.position = Vector2(max_map_size.x / 2 * tile_size.x, max_map_size.y / 2 * tile_size.y)
	$Player.curr_chunk = Vector2(position.x / tile_size.x / 32, position.y / tile_size.y / 32)
	$Player.prev_chunk = $Player.curr_chunk
	$Player.limit_left = 0
	$Player.limit_right = max_map_size.x * tile_size.x
	$Player.limit_top = 0
	$Player.limit_bottom = max_map_size.y * tile_size.y
	$Player.connect("show_resource_map", self, "_on_show_resource_map")
	$Player.connect("hide_resource_map", self, "_on_hide_resource_map")
	$Player.connect("get_hud_node", self, "_on_get_hud_node")
	$Player.connect("chunk_change", self, "_on_chunk_change")

func _generate_chunk(chunk_size, map_pos):
	for x in range(map_pos.x, map_pos.x + chunk_size.x):
		for y in range(map_pos.y , map_pos.y + chunk_size.y):
			$Ground.set_cellv(Vector2(x - chunk_size.x / 2, y - chunk_size.y / 2), randi() % num_tiles)
			$Resources.set_cellv(Vector2(x - chunk_size.x / 2, y - chunk_size.y / 2), 8)
	
	_generate_chunk_resources(chunk_size, map_pos)
	
	var amount_craters = (randi() % num_max_craters_per_chunk) + 1
	for i in amount_craters:
		if amount_craters * 4 <= chunk_size.x * chunk_size.y:
			var pos = Vector2((randi() % int(chunk_size.x)) - int(chunk_size.x / 2), (randi() % int(chunk_size.y)) - int(chunk_size.y / 2))
			# Check for overlay with existing craters
			while $Ground.get_cellv(pos) == 4 or $Ground.get_cellv(pos) == 5 or $Ground.get_cellv(pos) == 6 or $Ground.get_cellv(pos) == 7 or $Ground.get_cellv(Vector2(pos.x + 1, pos.y)) == 4 or $Ground.get_cellv(Vector2(pos.x + 1, pos.y)) == 5 or $Ground.get_cellv(Vector2(pos.x + 1, pos.y)) == 6 or $Ground.get_cellv(Vector2(pos.x + 1, pos.y)) == 7 or $Ground.get_cellv(Vector2(pos.x, pos.y + 1)) == 4 or $Ground.get_cellv(Vector2(pos.x, pos.y + 1)) == 5 or $Ground.get_cellv(Vector2(pos.x, pos.y + 1)) == 6 or $Ground.get_cellv(Vector2(pos.x, pos.y + 1)) == 7 or $Ground.get_cellv(Vector2(pos.x + 1, pos.y + 1)) == 4 or $Ground.get_cellv(Vector2(pos.x + 1, pos.y + 1)) == 5 or $Ground.get_cellv(Vector2(pos.x + 1, pos.y + 1)) == 6 or $Ground.get_cellv(Vector2(pos.x + 1, pos.y + 1)) == 7:
				pos = Vector2((randi() % int(chunk_size.x)) - chunk_size.x / 2, (randi() % int(chunk_size.y)) - chunk_size.y / 2)
			
			$Ground.set_cellv(Vector2(pos.x, pos.y), 4)
			$Ground.set_cellv(Vector2(pos.x + 1, pos.y), 5)
			$Ground.set_cellv(Vector2(pos.x, pos.y + 1), 6)
			$Ground.set_cellv(Vector2(pos.x + 1, pos.y + 1), 7)

func _generate_chunk_resources(chunk_size, pos):
	var noise = OpenSimplexNoise.new()
	noise.seed = map_seed
	noise.octaves = 2
	noise.period = 32
	noise.persistence = 0.3
	noise.lacunarity = 1

	for x in range(pos.x, pos.x + chunk_size.x):
		for y in range(pos.y, pos.y + chunk_size.y):
			if _check_treshold(noise.get_noise_2d(float(x), float(y))):
				if y == pos.y:
					if _check_treshold(noise.get_noise_2d(float(x), float(y - 1))):
						var id = $Resources.get_cellv(Vector2(x, y - 1))
						if id > 8 and id < num_resources + 9:
							_fill_resource_patch(Vector2(x, y), id, noise, chunk_size) 
				if y == pos.y + chunk_size.y - 1:
					if _check_treshold(noise.get_noise_2d(float(x), float(y + 1))):
						var id = $Resources.get_cellv(Vector2(x, y + 1))
						if id > 8 and id < num_resources + 9:
							_fill_resource_patch(Vector2(x, y), id, noise, chunk_size) 
				if x == pos.x:
					if _check_treshold(noise.get_noise_2d(float(x - 1), float(y))):
						var id = $Resources.get_cellv(Vector2(x - 1, y))
						if id > 8 and id < num_resources + 9:
							_fill_resource_patch(Vector2(x, y), id, noise, chunk_size) 
				if x == pos.x + chunk_size.x - 1:
					if _check_treshold(noise.get_noise_2d(float(x + 1), float(y))):
						var id = $Resources.get_cellv(Vector2(x + 1, y))
						if id > 8 and id < num_resources + 9:
							_fill_resource_patch(Vector2(x, y), id, noise, chunk_size)
	
	for x in range(pos.x, pos.x + chunk_size.x):
		for y in range(pos.y, pos.y + chunk_size.y):
			if _check_treshold(noise.get_noise_2d(float(x), float(y))):
				if $Resources.get_cellv(Vector2(x, y)) == 8:
					_fill_resource_patch(Vector2(x, y), (randi() % num_resources) +9, noise, chunk_size)

func _fill_resource_patch(pos, id, noise, chunk_size):
	if $Resources.get_cellv(Vector2(pos.x - chunk_size.x / 2, pos.y - chunk_size.y / 2)) == 8 and noise.get_noise_2d(pos.x, pos.y) > resource_threshold:
		$Resources.set_cellv(Vector2(pos.x - chunk_size.x / 2, pos.y - chunk_size.y / 2) , id)
		_fill_resource_patch(Vector2(pos.x, pos.y + 1), id, noise, chunk_size)
		_fill_resource_patch(Vector2(pos.x, pos.y - 1), id, noise, chunk_size)
		_fill_resource_patch(Vector2(pos.x - 1, pos.y), id, noise, chunk_size)
		_fill_resource_patch(Vector2(pos.x + 1, pos.y), id, noise, chunk_size)
	return

func _check_treshold(noise_sample):
	if noise_sample > resource_threshold:
		return true
	return false

func _set_camera_limits():
	$Player/Camera2D.limit_left = 0
	$Player/Camera2D.limit_right = max_map_size.x * tile_size.x
	$Player/Camera2D.limit_top = 0
	$Player/Camera2D.limit_bottom = max_map_size.y * tile_size.y

func _on_show_resource_map():
	$Resources.show()

func _on_hide_resource_map():
	$Resources.hide()

func _on_get_hud_node():
	$Player.hud = get_node("HUD")

func _on_chunk_change():
	for i in range(0, 9):
		if $Ground.get_cellv(Vector2($Player.curr_chunk.x * 32 + chunk_x_offsets[i], $Player.curr_chunk.y * 32 + chunk_y_offsets[i])) == -1:
			_generate_chunk(chunk_size, Vector2($Player.curr_chunk.x * 32 + chunk_x_offsets[i], $Player.curr_chunk.y * 32 + chunk_y_offsets[i]))