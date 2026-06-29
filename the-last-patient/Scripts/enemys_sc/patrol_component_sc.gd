extends Node
class_name PatrolComponent

# Sinal emitido quando o player é avistado pelo componente de patrulha
signal player_avistado(player_position: Vector2)

# --- CONFIGURAÇÕES ---
@export var move_speed: float = 60.0
@export var raio_exploracao: float = 250.0 # O quão longe ele escolhe o próximo ponto
@export var tempo_espera_ponto: float = 1.5 # Tempo que ele fica parado ao chegar num ponto

# --- ESTADOS INTERNOS ---
var destino_atual: Vector2 = Vector2.ZERO
var aguardando: bool = false
var direcao_atual: Vector2 = Vector2.ZERO

func _ready() -> void:
	# Garante que o ponto inicial seja onde ele deu spawn
	await get_tree().physics_frame
	definir_novo_destino_aleatorio(get_parent())

func process_patrol(body: CharacterBody2D, delta: float):
	# 1. Constantemente checa se o player entrou no campo de visão físico
	_checar_presenca_do_player(body)
	
	# 2. Interagir com portas à frente se estiver bloqueado
	if body.is_on_wall():
		_tentar_interagir_com_portas(body)
		definir_novo_destino_aleatorio(body) # Escolhe outro rumo se bateu na parede
		return

	if aguardando:
		body.velocity = Vector2.ZERO
		return

	# 3. Movimentação usando o NavigationAgent2D do próprio inimigo
	var nav_agent = body.get_node_or_null("NavigationAgent2D")
	if nav_agent:
		nav_agent.target_position = destino_atual
		
		if not nav_agent.is_navigation_finished():
			var proxima_posicao = nav_agent.get_next_path_position()
			direcao_atual = body.global_position.direction_to(proxima_posicao).normalized()
			body.velocity = direcao_atual * move_speed
			body.move_and_slide()
		else:
			# Chegou ao destino aleatório, espera um pouco antes de ir para o próximo
			_esperar_no_ponto(body)
	else:
		# Backup caso você não use NavigationAgent2D (Movimento linear simples)
		if body.global_position.distance_to(destino_atual) > 10.0:
			direcao_atual = body.global_position.direction_to(destino_atual).normalized()
			body.velocity = direcao_atual * move_speed
			body.move_and_slide()
		else:
			_esperar_no_ponto(body)

# --- LÓGICA DE EXPLORAÇÃO ---

func definir_novo_destino_aleatorio(body: CharacterBody2D):
	# Gera um vetor aleatório em 360 graus dentro do raio de exploração
	var angulo_aleatorio = randf_range(0, 2 * PI)
	var distancia_aleatoria = randf_range(raio_exploracao * 0.5, raio_exploracao)
	var offset = Vector2(cos(angulo_aleatorio), sin(angulo_aleatorio)) * distancia_aleatoria
	
	destino_atual = body.global_position + offset

func _esperar_no_ponto(body: CharacterBody2D):
	aguardando = true
	body.velocity = Vector2.ZERO
	
	await get_tree().create_timer(tempo_espera_ponto).timeout
	
	aguardando = false
	definir_novo_destino_aleatorio(body)

# --- INTERAÇÃO COM O CENÁRIO (PORTAS) ---

func _tentar_interagir_com_portas(body: CharacterBody2D):
	# Cria uma pequena área de colisão temporária à frente para detectar portas
	# Ou assume que há uma Area2D no monstro para coletar corpos encostando nele
	var hitbox = body.get_node_or_null("HitBox")
	if hitbox:
		var areas = hitbox.get_overlapping_areas()
		for area in areas:
			# Se a porta for uma Area2D ou tiver um script com o método de abrir
			if area.is_in_group("Portas") or area.has_method("abrir_porta"):
				if area.has_method("abrir_porta"):
					area.abrir_porta()
					print("Monstro abriu uma porta no caminho.")

# --- DETECÇÃO DO JOGADOR ---

func _checar_presenca_do_player(body: CharacterBody2D):
	# Pega o nó do player na cena para verificar proximidade/visão
	var player = get_tree().get_first_node_in_group("player")
	if is_instance_valid(player):
		# Se você tiver uma Area2D de visão no inimigo, use-a aqui. 
		# Exemplo genérico checando se o player entrou no raio de visão por colisão:
		var area_visao = body.get_node_or_null("HitBox") # Ou AreaVisao
		if area_visao and player in area_visao.get_overlapping_bodies():
			# Dispara o sinal avisando que o player foi encontrado
			player_avistado.emit(player.global_position)

func get_facing_direction() -> Vector2:
	return direcao_atual
