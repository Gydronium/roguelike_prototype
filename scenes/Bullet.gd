extends RigidBody2D

export var deathParticle : PackedScene

onready var _animation_player = $AnimationPlayer

var is_reflected_by_player := false
var reflect_speed = 50

func _integrate_forces(state: Physics2DDirectBodyState) -> void:
	if state.get_contact_count() > 0:
		var body = state.get_contact_collider_object(0)
		if body != null and body.is_in_group("weapon") and abs(body.angular_velocity) > PI / 2:
			state.linear_velocity = Vector2.ZERO
			state.angular_velocity = 0
			applied_force = Vector2.ZERO
			collision_mask = 4
			collision_layer = 16
			
			is_reflected_by_player = true
			var launcher = get_parent().get_parent()
			var direction = (launcher.global_position - global_position).normalized()
			
			apply_central_impulse(direction * reflect_speed)
			
			_animation_player.play("reflect")
			
		elif is_reflected_by_player and body == get_parent().get_parent():
			if body.has_method("damage"):
				var force = Vector2()
				var collision_damage = Vector2(1, 2) * state.linear_velocity / 10
				body.call_deferred("damage", collision_damage, state.get_contact_collider_position(0), force, 0, self, Color(1,1,1,1))
			kill()
		else:
			kill()

func _on_Timer_timeout():
	kill()

func kill():
	var _particle = deathParticle.instance()
	_particle.position = global_position
	_particle.rotation = global_rotation
	_particle.emitting = true
	get_tree().current_scene.add_child(_particle)
	
	queue_free()
