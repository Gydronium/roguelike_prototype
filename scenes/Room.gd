extends RigidBody2D

signal PlayerEntered(position, size_in_tiles)

var size
var size_in_tiles: Vector2
var visited: bool = false

func make_room(_pos, _size):
	position = _pos
	size = _size
	var shape = RectangleShape2D.new()
	shape.custom_solver_bias = 0.75
	shape.extents = size
	$CollisionShape2D.shape = shape

func set_area2d_collision(_size):
	var shape = RectangleShape2D.new()
	shape.extents = _size
	$Area2D/CollisionShape2D.shape = shape

func _on_Area2D_body_entered(body):
	if !visited and body.is_in_group("player"):
		visited = true
		emit_signal("PlayerEntered", body, position, size_in_tiles)

func set_size_in_tiles(_size: Vector2):
	size_in_tiles = _size

