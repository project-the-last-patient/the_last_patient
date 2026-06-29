extends Area2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
const amount := 2

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		
		anim.play("collected")
		
		set_deferred("monitoring", false)
		
		if body.has_method("take_life"):
			body.take_life(amount)


func _on_animated_sprite_2d_animation_finished() -> void:
	if anim.animation == "collected":
		queue_free()
