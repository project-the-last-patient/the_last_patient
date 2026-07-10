extends CharacterBody2D

# --- VARIÁVEIS CONFIGURÁVEIS ---
@export_category("Movimentação")
@export var velocidade_maxima : float = 300.0
@export var aceleracao : float = 2000.0
@export var friccao : float = 1800.0

@export_category("Opções")
@export var normalizar_diagonal : bool = true

# --- VARIÁVEIS INTERNAS ---
var direcao_input : Vector2 = Vector2.ZERO

func _physics_process(delta: float) -> void:
	# 1. Captura os comandos do teclado/controle
	obter_input_direcao()
	
	# 2. Processa a aceleração ou frenagem
	if direcao_input != Vector2.ZERO:
		aplicar_aceleracao(delta)
	else:
		aplicar_friccao(delta)
	
	# 3. Executa a movimentação física da engine
	move_and_slide()

# --- FUNÇÕES MODULARES ---

func obter_input_direcao() -> void:
	# Captura os eixos X e Y baseados nas ações do Input Map
	direcao_input.x = Input.get_axis("mov_left", "mov_right")
	direcao_input.y = Input.get_axis("mov_up", "mov_down")
	
	# Impede que o personagem ande mais rápido quando se move na diagonal
	if normalizar_diagonal and direcao_input.length() > 1.0:
		direcao_input = direcao_input.normalized()

func aplicar_aceleracao(delta: float) -> void:
	# Transiciona suavemente da velocidade atual para a máxima
	velocity = velocity.move_toward(direcao_input * velocidade_maxima, aceleracao * delta)

func aplicar_friccao(delta: float) -> void:
	# Faz o personagem parar de forma suave quando nenhum botão é pressionado
	velocity = velocity.move_toward(Vector2.ZERO, friccao * delta)
