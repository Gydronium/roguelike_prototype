extends RigidBody2D


export (int) var speed = 500

onready var target = position
var velocity = Vector2()


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func get_input():
	target = get_global_mouse_position()
	
func _physics_process(delta):
	var target = get_global_mouse_position()
	var velocity_vector = target - global_position
	var norm_vector = velocity_vector.normalized()
	if (global_position.distance_to(target) > 10):
		applied_force = norm_vector * speed
	else:
		applied_force = Vector2()
		
