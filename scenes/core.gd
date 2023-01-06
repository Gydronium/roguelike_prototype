extends Node2D


export(Color) var fracture_body_color

export var info_panel_path: NodePath

var _cur_fracture_color : Color = fracture_body_color
var _fracture_disabled : bool = false

onready var rigidbody_template = preload("res://src/RigidBody2D.tscn")
onready var polyFracture := PolygonFracture.new() 

onready var _blob_parent := $BlobParent
onready var _pool_fracture_shards := $Pool_FractureShards
onready var _pool_cut_visualizer := $Pool_CutVisualizer
onready var _source_polygon_parent := $SourceParent
onready var _rng := RandomNumberGenerator.new()

onready var _info_panel = get_node(info_panel_path)

func _ready() -> void:
	_rng.randomize()
	
#	var color := Color.white
#	color.s = fracture_body_color.s
#	color.v = fracture_body_color.v
#	color.h = _rng.randf()
#	_cur_fracture_color = color
#	_source_polygon_parent.modulate = _cur_fracture_color
	
	for blob in _blob_parent.get_children():
		blob.connect("Damaged", self, "On_Blob_Damaged")
		blob.connect("Fractured", self, "On_Blob_Fractured")

func _input(event):
	if event.is_action_released("reload_scene"):
		get_tree().reload_current_scene()
	elif event.is_action_released("info"):
		_info_panel.visible = !_info_panel.visible

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

