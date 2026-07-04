extends CharacterBody2D

@onready var health_component = $HealthComponent

@export var speed: float = 140.0

#movement
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
	
	
# morte

func _ready():
	# Conecta o sinal de morte do componente a uma função local do player
	if health_component:
		health_component.on_death.connect(_on_player_died)

# No topo do script do seu PLAYER, junto com as outras variáveis:
@export var cena_game_over: PackedScene

# ... resto do seu código ...

func _on_player_died():
	print("O player morreu!")
	
	# Verifica se você colocou alguma cena no slot do inspetor antes de carregar
	if cena_game_over:
		print("Carregando cena de Game Over personalizada...")
		get_tree().change_scene_to_packed(cena_game_over)
	else:
		# Backup caso você esqueça de arrastar a cena no editor, para o jogo não travar
		print("Aviso: cena_game_over não foi definida no Inspetor! Reiniciando cena atual por segurança.")
		get_tree().reload_current_scene()
