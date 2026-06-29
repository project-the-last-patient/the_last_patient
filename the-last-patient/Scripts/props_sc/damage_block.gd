extends Node2D

@export var wait_time := 1.0
@export var damage: int = 1

var target_rotation := 0

func _ready():
	start_loop()

func start_loop():
	while true:
		target_rotation += 90
		
		var tween = create_tween()
		tween.tween_property(self, "rotation_degrees", target_rotation, 0.3)
		
		await tween.finished
		await get_tree().create_timer(wait_time).timeout


func _on_spikes_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		if body.has_method("take_damage"):
			body.take_damage(damage)
	pass # Replace with function body.


func _on_spikes_2_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") or body.name == "Player":
		if body.has_method("take_damage"):
			body.take_damage(damage)
	pass # Replace with function body.
