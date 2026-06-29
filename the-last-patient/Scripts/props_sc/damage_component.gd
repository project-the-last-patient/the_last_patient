extends Node

@export var damage: int = 1
@export var invunerability: float = 0.25

func _ready():
	# Pegamos a referência do pai (que deve ser a Area2D)
	var area = get_parent()
	
	if area is Area2D:
		# Conectamos o sinal da variável 'area' à nossa função local
		area.body_entered.connect(_on_hit_detected)
	else:
		print("Erro: DamageComponent não encontrou uma Area2D como pai!")

func _on_hit_detected(body):
	if body.is_in_group("player") or body.name == "Player":

		while get_parent().overlaps_body(body):
			print("Dano causado ao Player!")
			
			if body.has_method("take_damage") and damage > 0:
				body.take_damage(damage)
			
			# Espera 1 segundo antes de continuar o loop
			await get_tree().create_timer(1.0).timeout
