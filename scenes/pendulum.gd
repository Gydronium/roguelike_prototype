extends RigidBody2D

signal Punch(strength)

export var strength: float = 1
export var torque_speed: float = 10000000

export var parent_node_path: NodePath
export var right_progress_bar_node_path: NodePath
export var left_progress_bar_node_path: NodePath
export var score_node_path: NodePath

onready var particles = $Trail

var right_progress_bar
var left_progress_bar
var scoreObj
var core_node

func _ready():
	if !core_node:
		core_node = get_node(parent_node_path)
	if !right_progress_bar:
		right_progress_bar = get_node(right_progress_bar_node_path)
	if !left_progress_bar:
		left_progress_bar = get_node(left_progress_bar_node_path)
	if !scoreObj:
		scoreObj = get_node(score_node_path)

func _physics_process(delta):
	if Input.is_action_just_pressed("Left mouse button"):
		apply_torque_impulse(-delta * torque_speed)
#		left_progress_bar.value += delta * 100
#		right_progress_bar.value = 0
		
	elif Input.is_action_just_pressed("Right mouse button"):
		apply_torque_impulse(delta * torque_speed)
#		right_progress_bar.value += delta * 100
#		left_progress_bar.value = 0
#	else:
#		right_progress_bar.value -= delta * 100
#		left_progress_bar.value -= delta * 100
	
	if right_progress_bar and left_progress_bar:
		if (angular_velocity > 0):
			right_progress_bar.value = angular_velocity
			left_progress_bar.value = 0
		else:
			left_progress_bar.value = -angular_velocity
			right_progress_bar.value = 0
		
	if (abs(angular_velocity) < 2):
		particles.emitting = false
	else:
		particles.emitting = true
#	particles.modulate.a = abs(angular_velocity) / 100

func set_nodes(_core_node, _right_progress_bar, _left_progress_bar, _scoreObj):
	core_node = _core_node
	right_progress_bar = _right_progress_bar
	left_progress_bar = _left_progress_bar
	scoreObj = _scoreObj

func _integrate_forces(state: Physics2DDirectBodyState) -> void:
	if state.get_contact_count() > 0:
#		var body = state.get_contact_collider_object(0)
#		if body is RigidBody2D:
#			var pos : Vector2 = state.get_contact_collider_position(0)
#			parent_node.fractureCollision(pos, body, angular_velocity * strength / 20)
		
		var collisions : Dictionary = {}
		#filtering the collisions
		for i in range(state.get_contact_count()):
			var id = state.get_contact_collider_id(i)
			if collisions.has(id):
				var shape = state.get_contact_collider_shape(i)
				collisions[id].shapes.append(shape)
			else:
				var body = state.get_contact_collider_object(i)
				var shape = state.get_contact_collider_shape(i)
				var pos = state.get_contact_collider_position(i)
				collisions[id] = {"body" : body, "shapes" : [shape], "pos" : pos}
		
		
		for col in collisions.values():
			if col.body is RigidBody2D:
				if col.body.has_method("damage"):
					var force = Vector2()
					var collision_damage = Vector2(5, 10) * state.angular_velocity * strength / 2
					col.body.call_deferred("damage", collision_damage, col.pos, force, 0, self, Color(1,1,1,1))
					scoreObj.add_score(abs(int(state.angular_velocity)))
					emit_signal("Punch", abs(state.angular_velocity * strength))
				elif col.body.has_method("get_polygon"):
					var pos : Vector2 = col.pos
					core_node.fractureCollision(pos, col.body, state.angular_velocity * strength / 20)
					scoreObj.add_score(abs(int(state.angular_velocity)))
					emit_signal("Punch", abs(state.angular_velocity * strength / 20))
					
