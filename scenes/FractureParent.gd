extends Node2D

signal Player_Is_Fighting(is_fighting)

export(Color) var fracture_body_color

onready var _rng := RandomNumberGenerator.new()
onready var polyFracture := PolygonFracture.new()

onready var rigidbody_template = preload("res://src/RigidBody2D.tscn")
onready var blob_template = preload("res://src/Blob.tscn")

onready var boundary = $Boundary
onready var pool_fracture_bodies = $Pool_FractureBodies
onready var visible_timer = $VisibleTImer
onready var slowdown_timer = $SlowdownTimer
onready var _blob_parent := $BlobParent
onready var _pool_fracture_shards := $Pool_FractureShards
onready var _pool_cut_visualizer := $Pool_CutVisualizer
onready var _source_polygon_parent := $SourceParent

var tile_size
var cuts: int = 10
var min_area: int = 25 
var _cur_fracture_color : Color = fracture_body_color
var _fracture_disabled : bool = false
var min_blob_radius = 100
var max_blob_radius = 150

var current_blob_number = 0

func _ready():
	_rng.randomize()

func _on_player_entered_room(player, pos, size_in_tiles):
	emit_signal("Player_Is_Fighting", true)
	
	var array_points = []
	
	var x_boundary_inner = size_in_tiles.x * tile_size + 10
	var x_boundary_outer = (size_in_tiles.x + 0.5) * tile_size + 10
	var y_boundary_inner = size_in_tiles.y * tile_size + 10
	var y_boundary_outer = (size_in_tiles.y + 0.5) * tile_size + 10
	
	var pos1_x = pos.x + x_boundary_outer
	var pos1_y = pos.y - y_boundary_inner
	array_points.append(Vector2(pos1_x, pos1_y))
	var pos2_x = pos1_x
	var pos2_y = pos.y - y_boundary_outer
	array_points.append(Vector2(pos2_x, pos2_y))
	var pos3_x = pos.x - x_boundary_outer
	var pos3_y = pos2_y
	array_points.append(Vector2(pos3_x, pos3_y))
	var pos4_x = pos3_x
	var pos4_y = pos.y + y_boundary_outer
	array_points.append(Vector2(pos4_x, pos4_y))
	var pos5_x = pos1_x
	var pos5_y = pos4_y
	array_points.append(Vector2(pos5_x, pos5_y))
	var pos6_x = pos5_x
	var pos6_y = pos.y - y_boundary_inner + 1
	array_points.append(Vector2(pos6_x, pos6_y))
	var pos7_x = pos.x + x_boundary_inner
	var pos7_y = pos6_y
	array_points.append(Vector2(pos7_x, pos7_y))
	var pos8_x = pos7_x
	var pos8_y = pos.y + y_boundary_inner
	array_points.append(Vector2(pos8_x, pos8_y))
	var pos9_x = pos.x - x_boundary_inner
	var pos9_y = pos8_y
	array_points.append(Vector2(pos9_x, pos9_y))
	var pos10_x = pos9_x
	var pos10_y = pos1_y
	array_points.append(Vector2(pos10_x, pos10_y))
	var pool_vector = PoolVector2Array(array_points)
	
	var static_body2d = StaticBody2D.new()
	var polygon2d = Polygon2D.new()
	polygon2d.set_polygon(pool_vector)
	polygon2d.color = Color.blueviolet
	static_body2d.add_child(polygon2d)
	var collision_polygon2d = CollisionPolygon2D.new()
	collision_polygon2d.set_polygon(pool_vector)
	static_body2d.add_child(collision_polygon2d)
	boundary.add_child(static_body2d)
	
	spawn_blobs(pos, x_boundary_inner, y_boundary_inner, player)

func set_tile_size(_size: int):
	tile_size = _size


func spawn_blobs(pos: Vector2, x_boundary_inner, y_boundary_inner, player):
	var blob_number = _rng.randi_range(1, 4)
	for i in range(blob_number):
		var blob = blob_template.instance()
		var blob_radius = _rng.randi_range(min_blob_radius, max_blob_radius)
		var blob_x_pos = _rng.randf_range(pos.x - x_boundary_inner + blob_radius, pos.x + x_boundary_inner - blob_radius)
		var blob_y_pos = _rng.randf_range(pos.y - y_boundary_inner + blob_radius, pos.y + y_boundary_inner - blob_radius)
		var is_shooting = _rng.randf_range(0.0, 1.0) > 0.7
		blob.init(Vector2(blob_x_pos, blob_y_pos), 0.5, Color.aquamarine, blob_radius, true, player, is_shooting, 500)
		blob.connect("Damaged", self, "On_Blob_Damaged")
		blob.connect("Fractured", self, "On_Blob_Fractured")
		blob.connect("Died", self, "On_Blob_Died")
		_blob_parent.add_child(blob)
	current_blob_number = blob_number


func _on_SlowdownTimer_timeout():
	Engine.time_scale = 1.0
	boundary.visible = true


#func _input(event: InputEvent) -> void:
#	if event.is_action_pressed("fracture") and boundary.visible:
#		fractureBounder()


func fractureBounder() -> void:
	slowdown_timer.start(0.35)
	Engine.time_scale = 0.1
	boundary.visible = false
	
	var source = boundary.get_child(0)
	var fracture_info : Array
		
	var polygon = source.get_child(0)
	fracture_info = polyFracture.fractureDelaunay(polygon.polygon, polygon.get_global_transform(), cuts, min_area)
		
	for entry in fracture_info:
		var texture_info : Dictionary = {"texture" : polygon.texture, "rot" : polygon.texture_rotation, "offset" : polygon.texture_offset, "scale" : polygon.texture_scale}
		spawnFractureBody3(entry, texture_info)
	
	source.queue_free()


func spawnFractureBody3(fracture_shard : Dictionary, texture_info : Dictionary) -> void:
	var instance = pool_fracture_bodies.getInstance()
	if not instance: 
		return
	
	instance.spawn(fracture_shard.spawn_pos)
	instance.global_rotation = fracture_shard.spawn_rot
	if instance.has_method("setPolygon"):
		var s : Vector2 = fracture_shard.source_global_trans.get_scale()
		instance.setPolygon(fracture_shard.centered_shape, s)


	instance.setColor(_cur_fracture_color)
	var dir : Vector2 = (fracture_shard.spawn_pos - fracture_shard.source_global_trans.get_origin()).normalized()
	instance.linear_velocity = dir * _rng.randf_range(200, 400)
	instance.angular_velocity = _rng.randf_range(-1, 1)

	instance.setTexture(PolygonLib.setTextureOffset(texture_info, fracture_shard.centroid))


func cutSourcePolygons(source, cut_pos : Vector2, cut_shape : PoolVector2Array, cut_rot : float, cut_force : float = 0.0, fade_speed : float = 2.0) -> void:
	spawnVisualizer(cut_pos, cut_shape, fade_speed)
	
	var source_polygon : PoolVector2Array = source.get_polygon()
	var total_area : float = PolygonLib.getPolygonArea(source_polygon)
	
	var source_trans : Transform2D = source.get_global_transform()
	var cut_trans := Transform2D(cut_rot, cut_pos)
	
	var s_lin_vel := Vector2.ZERO
	var s_ang_vel : float = 0.0
	var s_mass : float = 0.0
	
	if source is RigidBody2D:
		s_lin_vel = source.linear_velocity
		s_ang_vel = source.angular_velocity
		s_mass = source.mass
	
	
	var cut_fracture_info : Dictionary = polyFracture.cutFracture(source_polygon, cut_shape, source_trans, cut_trans, 2500, 1500, 100, 1)
	
	if cut_fracture_info.shapes.size() <= 0 and cut_fracture_info.fractures.size() <= 0:
		return
	
	for fracture in cut_fracture_info.fractures:
		for fracture_shard in fracture:
			var area_p : float = fracture_shard.area / total_area
			var rand_lifetime : float = _rng.randf_range(1.0, 3.0) + 2.0 * area_p
			spawnFractureBody(fracture_shard, source.getTextureInfo(), s_mass * area_p, rand_lifetime)
	
	
	for shape in cut_fracture_info.shapes:
		var area_p : float = shape.area / total_area
		var mass : float = s_mass * area_p
		var dir : Vector2 = (shape.spawn_pos - cut_pos).normalized()
		
		call_deferred("spawnRigibody2d", shape, source.modulate, s_lin_vel + (dir * cut_force) / mass, s_ang_vel, mass, cut_pos, source.getTextureInfo())
		
	source.queue_free()


func spawnFractureBody(fracture_shard : Dictionary, texture_info : Dictionary, new_mass : float, life_time : float) -> void:
	var instance = _pool_fracture_shards.getInstance()
	if not instance:
		return
	
	var dir : Vector2 = (fracture_shard.spawn_pos - fracture_shard.source_global_trans.get_origin()).normalized()
	instance.spawn(fracture_shard.spawn_pos, fracture_shard.spawn_rot, fracture_shard.source_global_trans.get_scale(), life_time)
	instance.setPolygon(fracture_shard.centered_shape, _cur_fracture_color, PolygonLib.setTextureOffset(texture_info, fracture_shard.centroid))
	instance.setMass(new_mass)


func spawnFractureBody2(fracture_shard : Dictionary, new_mass : float, color : Color, fracture_force : float, p : float) -> void:
	var instance = _pool_fracture_shards.getInstance()
	if not instance:
		return
	
	var dir : Vector2 = (fracture_shard.spawn_pos - fracture_shard.source_global_trans.get_origin()).normalized()
	instance.spawn(fracture_shard.spawn_pos, fracture_shard.spawn_rot, fracture_shard.source_global_trans.get_scale(), _rng.randf_range(2.0, 4.0))
	instance.setPolygon(fracture_shard.centered_shape, color, {})
	instance.setMass(new_mass)
	instance.addForce(dir * fracture_force * p)
	instance.addTorque(_rng.randf_range(-2, 2) * p)


func spawnVisualizer(pos : Vector2, poly : PoolVector2Array, fade_speed : float) -> void:
	var instance = _pool_cut_visualizer.getInstance()
	instance.spawn(pos, fade_speed)
	instance.setPolygon(poly)


func fractureCollision(pos : Vector2, other_body, p: float) -> void:
	if _fracture_disabled: return

	var cut_shape : PoolVector2Array = polyFracture.generateRandomPolygon(Vector2(25, 200) * p, Vector2(18,72), Vector2.ZERO)
	cutSourcePolygons(other_body, pos, cut_shape, 0.0, _rng.randf_range(400.0, 800.0), 2.0)

	_fracture_disabled = true
	set_deferred("_fracture_disabled", false)


func spawnRigibody2d(shape_info : Dictionary, color : Color, lin_vel : Vector2, ang_vel : float, mass : float, cut_pos : Vector2, texture_info : Dictionary) -> void:
	var instance = rigidbody_template.instance()
	_source_polygon_parent.add_child(instance)
	instance.global_position = shape_info.spawn_pos
	instance.global_rotation = shape_info.spawn_rot
	instance.set_polygon(shape_info.centered_shape)
	instance.modulate = color
	instance.linear_velocity = lin_vel
	instance.angular_velocity = ang_vel
	instance.mass = mass
	instance.setTexture(PolygonLib.setTextureOffset(texture_info, shape_info.centroid))


func spawnShapeVisualizer(cut_pos : Vector2, cut_shape : PoolVector2Array, fade_speed : float) -> void:
	var instance = _pool_cut_visualizer.getInstance()
	instance.spawn(cut_pos, fade_speed)
	instance.setPolygon(cut_shape)


func On_Blob_Damaged(blob, pos : Vector2, shape : PoolVector2Array, color : Color, fade_speed : float) -> void:
	spawnShapeVisualizer(pos, shape, fade_speed)

func On_Blob_Fractured(blob, fracture_shard : Dictionary, new_mass : float, color : Color, fracture_force : float, p : float) -> void:
	spawnFractureBody2(fracture_shard, new_mass, color, fracture_force, p)


func On_Blob_Died(ref, pos):
	current_blob_number -= 1
	if current_blob_number == 0:
		fractureBounder()
		emit_signal("Player_Is_Fighting", false)
