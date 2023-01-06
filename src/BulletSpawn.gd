extends Node2D

onready var bullet_template = preload("res://scenes/Bullet.tscn")
onready var cooldown_timer = $CooldownTimer

var _is_shooting: bool = false
var _target_pos = Vector2.ZERO
var _bullet_speed: float = 250
var _shooter_pos = Vector2.ZERO
var _radius = 0.0
var step
var current_shoot_mode = 0
var current_rotation = 0

var _rotate_speed = PI
var _spawn_point_count = 4
const modes_count = 2

func start(isShooting: bool, radius: float, rotate_speed = PI, spawn_point_count = 4, shoot_timer_wait = 1, bullet_speed = 250):
	_is_shooting = isShooting
	_radius = radius
	step = 2 * PI / spawn_point_count
	_spawn_point_count = spawn_point_count
	_rotate_speed = rotate_speed
	cooldown_timer.wait_time = shoot_timer_wait
	_bullet_speed = bullet_speed

func _process(delta):
	current_rotation = current_rotation + _rotate_speed * delta
	if Input.is_action_just_pressed("change_shoot_mode"):
		changeMode()

func changeMode():
	current_shoot_mode = (current_shoot_mode + 1) % modes_count
	if current_shoot_mode == 1:
		cooldown_timer.wait_time = 0.1
	elif current_shoot_mode == 0:
		cooldown_timer.wait_time = 1

func setTargetPos(pos: Vector2):
	_target_pos = pos

func setShooterPos(shooterPos: Vector2):
	_shooter_pos = shooterPos

func _on_CooldownTimer_timeout():
	if (_is_shooting):
		if (current_shoot_mode == 0):
			_spawn_bullet(_target_pos)
		elif (current_shoot_mode == 1):
			var rotation = current_rotation
			for i in range(_spawn_point_count):
				var pos = Vector2.LEFT.rotated(rotation + step * i)
				_spawn_bullet(pos)

func _spawn_bullet(pos: Vector2):
	var bullet = bullet_template.instance()
	bullet.position = pos * _radius
	bullet.apply_central_impulse(pos * _bullet_speed)
	add_child(bullet)
