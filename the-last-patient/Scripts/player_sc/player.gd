extends CharacterBody2D

@export var speed: float = 300.0

func _physics_process(_delta: float) -> void:

	# O get_vector já lida com a normalização automaticamente!
	var direction := Input.get_vector("mov_left", "mov_right", "mov_up", "mov_down")
	
	# 2. Aplica a direção à velocidade
	if direction != Vector2.ZERO:
		velocity = direction * speed
	else:
		# Suaviza a parada (opcional, para um movimento menos travado)
		velocity = velocity.move_toward(Vector2.ZERO, speed)

	move_and_slide()
