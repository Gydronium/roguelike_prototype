extends Camera2D

export var shake_amount = 0;
export var interpolate_val = 1
export (NodePath) var player_node_path

onready var tween = $Tween
onready var timer = $Timer

var default_offset = offset
var is_shaking: bool = false
var player

func _ready():
	var weapon_objects = get_tree().get_nodes_in_group("weapon")
	for weapon in weapon_objects:
		weapon.connect("Punch", self, "_on_weapon_punch")
	if (!player):
		player = get_node(player_node_path)

func set_player(_player):
	player = _player

func _process(delta):
	var target = player.global_position 
	var global_mouse_position = get_global_mouse_position()
	var mid_x = (target.x + global_mouse_position.x) / 2
	var mid_y = (target.y + global_mouse_position.y) / 2
	
	var position_to_move = Vector2(mid_x,mid_y)
	if global_position.distance_to(position_to_move) > 200:
		global_position = global_position.linear_interpolate(Vector2(mid_x,mid_y), interpolate_val * delta)
	
	if is_shaking:
		_shake()

func _shake():
	offset = Vector2(rand_range(-1, 1) * shake_amount, rand_range(-1, 1) * shake_amount)

func _on_weapon_punch(amount):
	timer.wait_time = 0.5
	shake_amount = amount
	is_shaking = true
	timer.start()


func _on_Timer_timeout():
	is_shaking = false
	tween.interpolate_property(self, "offset", offset, default_offset, 0.5, 6, 2)
	tween.start()
