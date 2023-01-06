extends MarginContainer

export (NodePath) var player_node_path

onready var player_icon = $NinePatchRect/PlayerIcon
onready var enemy_icon = $NinePatchRect/EnemyIcon
onready var ninepatch_rect = $NinePatchRect

var markers = {}
var world_constraint = Rect2(Vector2(0, 0), Vector2(8000, 8000)) # Vector2(8000, 8000)
var minimap_constraint = Vector2(180, 180)
var player
var tiles: Array
var tile_size: int
var start_room_pos: Vector2
var end_room_pos: Vector2
var font

func _ready():
	var map_objects = get_tree().get_nodes_in_group("minimap_objects")
	for item in map_objects:
		var icon = enemy_icon.duplicate()
		ninepatch_rect.add_child(icon)
		icon.show()
		markers[item] = icon
		item.connect("Died", self, "_on_Blob_Died")
	if !player:
		player = get_node(player_node_path)
	player_icon.show()
	markers[player] = player_icon
	create_font()

func _process(delta):
	for item in markers:
		markers[item].position = get_position_on_minimap(item)

func get_position_on_minimap(node: Node2D) -> Vector2:
	var x = node.global_position.x / world_constraint.size.x * minimap_constraint.x + minimap_constraint.x / 2
	var y = node.global_position.y / world_constraint.size.y * minimap_constraint.y + minimap_constraint.y / 2
	return Vector2(x, y)


func _on_Blob_Died(ref, pos):
	var removeIcon = markers[ref]
	markers.erase(ref)
	ninepatch_rect.remove_child(removeIcon)
	removeIcon.queue_free()

func set_player(_player):
	player = _player

func set_constraint(_world_constraint: Rect2):
	world_constraint = _world_constraint

func _draw():
	if tiles:
		var relative_tile_size_x = tile_size / world_constraint.size.x * minimap_constraint.x
		var relative_tile_size_y = tile_size / world_constraint.size.y * minimap_constraint.y
		for tile in tiles:
			draw_rect(Rect2((tile.x + 1) * relative_tile_size_x + minimap_constraint.y / 2, 
					(tile.y + 1) * relative_tile_size_y + minimap_constraint.y / 2, 
					relative_tile_size_x, relative_tile_size_y), Color.white, true, 0.0)
		
		var minimap_start_x = start_room_pos.x / world_constraint.size.x * minimap_constraint.x + minimap_constraint.x / 2 - 2
		var minimap_start_y = start_room_pos.y / world_constraint.size.y * minimap_constraint.y + minimap_constraint.y / 2
		draw_string(font, Vector2(minimap_start_x, minimap_start_y), "start", Color.black)
		var minimap_end_x = end_room_pos.x / world_constraint.size.x * minimap_constraint.x + minimap_constraint.x / 2 - 2
		var minimap_end_y = end_room_pos.y / world_constraint.size.y * minimap_constraint.y + minimap_constraint.y / 2
		draw_string(font, Vector2(minimap_end_x, minimap_end_y), "end", Color.black)


func set_tiles(_tiles: Array, _tile_size: int, _start_room_pos: Vector2, _end_room_position: Vector2):
	tiles = _tiles
	tile_size = _tile_size
	start_room_pos = _start_room_pos
	end_room_pos = _end_room_position


func create_font():
	font = DynamicFont.new()
	font.font_data = load("res://Comic Sans MS.ttf")
	font.size = 5
