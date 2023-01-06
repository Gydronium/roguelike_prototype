extends Sprite


onready var animationPlayer = $AnimationPlayer

var shockwaveIsOn: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	var weapon_objects = get_tree().get_nodes_in_group("weapon")
	for weapon in weapon_objects:
		weapon.connect("Punch", self, "_on_weapon_punch")

func _input(event):
	if event.is_action_pressed("shockwave_on_off"):
		shockwaveIsOn = !shockwaveIsOn

func _on_weapon_punch(strength):
	if (shockwaveIsOn):
		animationPlayer.stop()
		material.set_shader_param("thickness", strength / 50)
		animationPlayer.play("shockwave")
