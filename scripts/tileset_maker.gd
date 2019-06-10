extends Node

export(Vector2) var tile_size
onready var texture = $Sprite.texture

func _ready():
	var texture_w = texture.get_width() / tile_size.x
	var texture_h = texture.get_height() / tile_size.y
	var tileset = TileSet.new();
	
	for x in range(texture_w):
		for y in range(texture_h):
			var region = Rect2(x * tile_size.x, y * tile_size.y, tile_size.x, tile_size.y)
			var id = x + y * texture_w
			
			tileset.create_tile(id)
			tileset.tile_set_texture(id, texture);
			tileset.tile_set_region(id, region);
	
	ResourceSaver.save("res://terrain/tiles.tres", tileset);