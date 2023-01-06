extends Node2D

onready var player_template = preload("res://scenes/player3.tscn")
onready var camera2d_template = preload("res://scenes/Camera2D.tscn")
onready var minimap_template = preload("res://scenes/Minimap.tscn")
onready var texture = load("res://smiley_face.png")

onready var map = $Map
onready var canvas_layer = $CanvasLayer
onready var fracture_parent = $FractureParent
onready var _info_panel = $CanvasLayer/InfoPanel
onready var _right_progress_bar = $CanvasLayer/RightProgressBar
onready var _left_progress_bar = $CanvasLayer/LeftProgressBar
onready var _score = $CanvasLayer/ScoreLabel
onready var wave_function_collapse = $FractureParent/WaveFunctionCollapse

var exit_zone_radius = 200.0
var player_is_fighting = false

func _ready():
	map.generate_map()
	yield(map, "Map_Was_Created")
	var start_room_pos = map.get_start_room_position()
	var end_room_position = map.get_end_room_position()
	
	# exit area to next level
	var shape = RectangleShape2D.new()
	shape.extents = Vector2(exit_zone_radius, exit_zone_radius)
	var exit_collision_shape = CollisionShape2D.new()
	exit_collision_shape.shape = shape
	var exit_area2d = Area2D.new()
	exit_area2d.add_child(exit_collision_shape)
	var sprite = Sprite.new()
	sprite.texture = wave_function_collapse.generate_image_texture(exit_zone_radius * 2, exit_zone_radius * 2)
	exit_area2d.add_child(sprite)
	exit_area2d.connect("body_entered", self, "_on_exit_area_player_entered")
	exit_area2d.position = end_room_position
	add_child(exit_area2d)
	
	var player = player_template.instance()
	player.position = start_room_pos
	add_child(player)
	player.set_nodes_for_weapon(fracture_parent, _right_progress_bar, _left_progress_bar, _score)
	var camera2d = camera2d_template.instance()
	camera2d.set_player(player)
	camera2d.position = start_room_pos
	camera2d.current = true
	camera2d.zoom = Vector2(2, 2)
	add_child(camera2d)
	var minimap = minimap_template.instance()
	minimap.set_player(player)
	minimap.set_constraint(map.get_full_rect())
	minimap.set_tiles(map.get_tiles_with_id(0), map.get_tile_size(), start_room_pos, end_room_position)
	fracture_parent.set_tile_size(map.get_tile_size())
	canvas_layer.add_child(minimap)
	
	for room in get_tree().get_nodes_in_group("room"):
		room.connect("PlayerEntered", fracture_parent, "_on_player_entered_room")
		
func _input(event):
	if event.is_action_released("reload_scene"):
		get_tree().reload_current_scene()
	elif event.is_action_released("info"):
		_info_panel.visible = !_info_panel.visible

func _on_exit_area_player_entered(body):
	if body.is_in_group("player") and !player_is_fighting:
		get_tree().reload_current_scene()


func _on_FractureParent_Player_Is_Fighting(is_fighting):
	player_is_fighting = is_fighting
