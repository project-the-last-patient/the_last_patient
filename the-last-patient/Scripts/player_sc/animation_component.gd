extends Node
class_name AnimationComponent

@export var sprite: AnimatedSprite2D 

func handle_move_animation(
	
	velocity: Vector2, 
	is_on_floor: bool, 
	is_wall_sliding: bool, 
	should_flip: bool,
	is_dashing: bool
):
	if sprite.animation == "taunt" and sprite.is_playing() and velocity.length() < 10:
		return
	if is_dashing:
		sprite.play("dash")
	
	elif is_wall_sliding:
		sprite.play("wall")
	
	elif not is_on_floor:
		sprite.play("idle")
	
	elif velocity.x != 0:
		sprite.play("run")
	
	else:
		sprite.play("idle")

	sprite.flip_h = should_flip
func play_action(anim_name: String):
	if sprite:
		sprite.play(anim_name)
