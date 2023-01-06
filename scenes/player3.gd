extends RigidBody2D

export (int) var speed = 50000

onready var pendulum = $RigidBody2D


func _physics_process(delta):
	var target = get_global_mouse_position()
	var velocity_vector = target - global_position
	var norm_vector = velocity_vector.normalized()
	var speedModificator = global_position.distance_to(target) / 100
	speedModificator = clamp(speedModificator, 0.0, 1.0)
	applied_force = norm_vector * speed * speedModificator
	

func set_nodes_for_weapon(_core_node, _right_progress_bar, _left_progress_bar, _scoreObj):
	pendulum.set_nodes(_core_node, _right_progress_bar, _left_progress_bar, _scoreObj)
