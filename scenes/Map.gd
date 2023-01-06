extends Node2D

signal Map_Was_Created()

var room = preload("res://scenes/Room.tscn")

onready var rng = RandomNumberGenerator.new()
onready var rooms = $Rooms
onready var tile_map: TileMap = $TileMap

var tile_size = 256                 # size of a tile in the TileMap
var num_rooms = 20                  # number of rooms to generate
var min_size = 5                    # min number of tiles in room
var max_size = 12                   # max number of tiles in room
var hspread = 1000                  # horizontal spread in pixels
var cull = 0.5                      # chance to cull room

var path                            # AStar pathfinding object

var start_room_pos                  # most left room
var end_room_pos                    # most right room
var full_rect                       # world constraints

func _ready():
	rng.randomize()
#	make_rooms()

func generate_map():
	for r in rooms.get_children():
		r.queue_free()
	path = null
	make_rooms()
	yield(get_tree().create_timer(1.5), "timeout")
	make_map()
	emit_signal("Map_Was_Created")
	

func make_rooms():
	for i in range(num_rooms):
		var pos = Vector2(rng.randf_range(-hspread, hspread), 0)
		var r = room.instance()
		var width = rng.randi_range(min_size, max_size)
		var height = rng.randi_range(min_size, max_size)
		r.make_room(pos, Vector2(width, height) * tile_size)
		rooms.add_child(r)
	# wait for movement to stop
	yield(get_tree().create_timer(1.1), "timeout")
	# cull rooms
	var room_positions = []
	var _start_room_pos = Vector2.INF
	var _end_room_pos = -Vector2.INF
	for room in $Rooms.get_children():
		if rng.randf() < cull:
			room.queue_free()
		else:
			var room_pos = room.position
			room.mode = RigidBody2D.MODE_STATIC
			room_positions.append(room_pos)
			if _start_room_pos > room_pos:
				_start_room_pos = room_pos
			if _end_room_pos < room_pos:
				_end_room_pos = room_pos
	
	start_room_pos = _start_room_pos
	end_room_pos = _end_room_pos
	
	yield(get_tree(), 'idle_frame')
	# generate a minimum spanning tree connecting rooms
	path = find_mst(room_positions)

func _draw():
#	for room in rooms.get_children():
#		draw_rect(Rect2(room.position - room.size, room.size * 2), Color(32, 228, 0), false)
#
#	if path:
#		for p in path.get_points():
#			for c in path.get_point_connections(p):
#				var pp = path.get_point_position(p)
#				var cp = path.get_point_position(c)
#				draw_line(pp, cp, Color(1, 1, 0), 15, true)
	pass

func _process(delta):
	update()

#func _input(event):
#	if event.is_action_pressed('ui_select'):
#		for r in rooms.get_children():
#			r.queue_free()
#		path = null
#		tile_map.clear()
#		make_rooms()
#	if event.is_action_pressed("ui_focus_next"):
#		make_map()

func find_mst(nodes):
	# Prim's algorithm
	var path = AStar2D.new()
	path.add_point(path.get_available_point_id(), nodes.pop_front())
	
	# repeat until no more nodes remain
	while nodes:
		var min_dist = INF  # Minimum distance instantioation
		var min_p = null  # Postition of that node
		var p = null  # Current position
		# Loop through points in path
		for p1 in path.get_points():
			p1 = path.get_point_position(p1)
			# Loop through the remaining nodes
			for p2 in nodes:
				var dist = p1.distance_to(p2)
				if dist < min_dist:
					min_dist = dist
					min_p = p2
					p = p1
		var n = path.get_available_point_id()
		path.add_point(n, min_p)
		path.connect_points(path.get_closest_point(p), n)
		nodes.erase(min_p)
	return path

func make_map():
	# Create a TileMap from the generated rooms and path
	tile_map.clear()
	
	# Fill TileMap with walls, then carve empty rooms
	var _full_rect = Rect2()
	for room in rooms.get_children():
		var room_collision = room.get_node("CollisionShape2D")
		var r = Rect2(room.position - room.size, room.get_node("CollisionShape2D").shape.extents * 2)
		_full_rect = _full_rect.merge(r)
		room_collision.queue_free()
	full_rect = _full_rect
	var topleft = tile_map.world_to_map(_full_rect.position)
	var bottomright = tile_map.world_to_map(_full_rect.end)
	for x in range(topleft.x, bottomright.x):
		for y in range(topleft.y, bottomright.y):
			tile_map.set_cell(x, y, 1)
	
	# Carve rooms
	var corridors = [] # One corridor per connection
	for room in rooms.get_children():
		var s = (room.size / tile_size).floor()
		var pos = tile_map.world_to_map(room.position)
		var ul = (room.position / tile_size).floor() - s
		for x in range(2, s.x * 2 - 1):
			for y in range (2, s.y * 2 - 1):
				tile_map.set_cell(ul.x + x, ul.y + y, 0)
		# Add area2d collision shape
		room.set_area2d_collision(Vector2((s.x - 2) * tile_size, (s.y - 2) * tile_size))
		room.set_size_in_tiles(Vector2(s.x - 2, s.y - 2))
		# Carve connecting corridor
		var p = path.get_closest_point(room.position)
		for conn in path.get_point_connections(p):
			if not conn in corridors:
				var start = tile_map.world_to_map(path.get_point_position(p))
				var end = tile_map.world_to_map(path.get_point_position(conn))
				carve_path(start, end)
		corridors.append(p)

func carve_path(pos1, pos2):
	# Carve a path between two points
	var x_diff = sign(pos2.x - pos1.x)
	var y_diff = sign(pos2.y - pos1.y)
	if x_diff == 0:
		x_diff = pow(-1.0, rng.randi() % 2)
	if y_diff == 0:
		y_diff = pow(-1.0, rng.randi() % 2)
	# choose either x/y or y/x
	var x_y = pos1
	var y_x = pos2
	if (rng.randi() % 2) > 0:
		x_y = pos2
		y_x = pos1
	for x in range(pos1.x, pos2.x, x_diff):
		tile_map.set_cell(x, x_y.y, 0)
		tile_map.set_cell(x, x_y.y + y_diff, 0)  # widen the corridor
		tile_map.set_cell(x, x_y.y + y_diff * 2, 0)
	for y in range(pos1.y, pos2.y, y_diff):
		tile_map.set_cell(y_x.x, y, 0)
		tile_map.set_cell(y_x.x + x_diff, y, 0)
		tile_map.set_cell(y_x.x + x_diff * 2, y, 0)

func get_start_room_position():
	return start_room_pos

func get_end_room_position():
	return end_room_pos

func get_full_rect() -> Rect2:
	return full_rect

func get_tiles_with_id(id: int) -> Array:
	return tile_map.get_used_cells_by_id(id)

func get_tile_size() -> int:
	return tile_size
