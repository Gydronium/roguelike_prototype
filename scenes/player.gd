extends KinematicBody2D


export (int) var speed = 500

onready var target = position
var velocity = Vector2()


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func get_input():
	target = get_global_mouse_position()
	
func _physics_process(delta):
	get_input()
	velocity = position.direction_to(target) * speed
	if position.distance_to(target) > 5:
		velocity = move_and_slide(velocity)
