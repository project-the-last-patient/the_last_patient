extends Area2D


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		
		# chama morte normal se existir
		if body.has_method("take_damage"):
			body.take_damage(999)
		
		# fallback
		body.queue_free()
	pass # Replace with function body.
