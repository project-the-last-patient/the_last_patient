extends Node
class_name PatrolComponent

# Sinal emitido quando o player é avistado pelo componente de patrulha
signal player_avistado(player_position: Vector2)

# --- CONFIGURAÇÕES ---
@export var move_speed: float = 50.0
@export var raio_exploracao: float = 250.0 
@export var tempo_espera_ponto: float = 1.5 

# --- ESTADOS INTERNOS ---
var destino_atual: Vector2 = Vector2.ZERO
var aguardando: bool = false
var direcao_atual: Vector2 = Vector2.ZERO

func _ready() -> void:
	print("[PatrolComponent] _ready iniciado.")
	await get_tree().physics_frame
	definir_novo_destino_aleatorio(get_parent())


func process_patrol(body: CharacterBody2D, _delta: float):
	# 1. Checa a presença do player (Com linha de visão limpa)
	_checar_presenca_do_player(body)
	
	# 2. Interagir com portas (Passando o 'body' para a função saber quem é o monstro)
	_checar_portas_a_frente(body)
	
	if body.is_on_wall():
		print("[PatrolComponent] Inimigo bateu na parede durante a patrulha. Mudando de rota.")
		definir_novo_destino_aleatorio(body)
		return

	if aguardando:
		body.velocity = Vector2.ZERO
		return

	var nav_agent = body.get_node_or_null("NavigationAgent2D")
	if nav_agent:
		nav_agent.target_position = destino_atual
		
		if not nav_agent.is_navigation_finished():
			var proxima_posicao = nav_agent.get_next_path_position()
			direcao_atual = body.global_position.direction_to(proxima_posicao).normalized()
			body.velocity = direcao_atual * move_speed
			body.move_and_slide()
		else:
			print("[PatrolComponent] Destino de navegação alcançado.")
			_esperar_no_ponto(body)
	else:
		if body.global_position.distance_to(destino_atual) > 10.0:
			direcao_atual = body.global_position.direction_to(destino_atual).normalized()
			body.velocity = direcao_atual * move_speed
			body.move_and_slide()
		else:
			print("[PatrolComponent] Destino linear alcançado.")
			_esperar_no_ponto(body)

# --- LÓGICA DE EXPLORAÇÃO ---

func definir_novo_destino_aleatorio(body: CharacterBody2D):
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

# --- INTERAÇÃO COM PORTAS 2D (PARADO OU ANDANDO) ---

# Criamos uma variável de controle no topo do PatrolComponent (junto com as outras)
var cooldown_interacao_porta: bool = false

func _checar_portas_a_frente(body: CharacterBody2D):
	# Se o monstro acabou de interagir com uma porta, espera ele se afastar ou o tempo passar
	if cooldown_interacao_porta:
		return

	var space_state = body.get_world_2d().direct_space_state
	var alcance_distancia = 45.0
	var direcao_do_raio = direcao_atual
	
	if direcao_do_raio == Vector2.ZERO:
		var direcoes_teste = [Vector2.RIGHT, Vector2.LEFT, Vector2.DOWN, Vector2.UP]
		
		for dir in direcoes_teste:
			var alcance_parado = body.global_position + (dir * alcance_distancia)
			var query_parado = PhysicsRayQueryParameters2D.create(body.global_position, alcance_parado)
			query_parado.collide_with_areas = true
			query_parado.collide_with_bodies = false
			query_parado.exclude = [body.get_rid()]
			
			var resultado_parado = space_state.intersect_ray(query_parado)
			if resultado_parado:
				var area = resultado_parado.collider
				if area is Area2D:
					_ativar_porta_com_seguranca(area, body)
					return
		return

	var alcance_raio = body.global_position + (direcao_do_raio * alcance_distancia)
	var query = PhysicsRayQueryParameters2D.create(body.global_position, alcance_raio)
	query.collide_with_areas = true
	query.collide_with_bodies = false
	query.exclude = [body.get_rid()]
	
	var resultado = space_state.intersect_ray(query)
	
	if resultado:
		var area = resultado.collider
		if area is Area2D:
			_ativar_porta_com_seguranca(area, body)

# Nova função auxiliar que gerencia o travamento do monstro na colisão
func _ativar_porta_com_seguranca(area: Area2D, monstro: CharacterBody2D):
	var node_alvo = area
	while node_alvo != null:
		if node_alvo.is_in_group("Doors") and node_alvo.has_method("monster_interact"):
			
			# Ativa o cooldown no componente do monstro ANTES de interagir
			cooldown_interacao_porta = true
			node_alvo.monster_interact(monstro)
			
			# FORÇA uma mudança de rota imediata para longe da porta antes que ele trave
			definir_novo_destino_aleatorio(monstro)
			
			# Espera 2 segundos antes de permitir que este monstro mexa em QUALQUER porta de novo
			# Isso dá tempo de sobra para ele dar o fora de perto da colisão física
			await get_tree().create_timer(2.0).timeout
			cooldown_interacao_porta = false
			return
		node_alvo = node_alvo.get_parent()

# Função auxiliar para subir na hierarquia do Node2D da porta e acionar a interação
func _processar_colisao_com_porta(area: Area2D, monstro: CharacterBody2D):
	var node_alvo = area
	while node_alvo != null:
		if node_alvo.is_in_group("Doors") and node_alvo.has_method("monster_interact"):
			node_alvo.monster_interact(monstro)
			return
		node_alvo = node_alvo.get_parent()

# --- DETECÇÃO DO JOGADOR ---

func _checar_presenca_do_player(body: CharacterBody2D):
	var fov = body.get_node_or_null("FOV")
	if not fov:
		return
		
	var corpos_no_fov = fov.get_overlapping_bodies()
	
	if corpos_no_fov.size() > 0:
		for corpo in corpos_no_fov:
			if corpo.is_in_group("Player") or corpo.name == "Player":
				if _tem_linha_de_visao_limpa(body, corpo):
					print("[DEBUG FOV] Player avistado com linha de visão limpa!")
					player_avistado.emit(corpo.global_position)
					break

func _tem_linha_de_visao_limpa(monstro: CharacterBody2D, player: Node2D) -> bool:
	var space_state = monstro.get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(monstro.global_position, player.global_position)
	query.exclude = [monstro.get_rid()]
	query.collide_with_areas = false
	query.collide_with_bodies = true
	
	var resultado = space_state.intersect_ray(query)
	
	if resultado:
		if resultado.collider == player:
			return true
	return false

func get_facing_direction() -> Vector2:
	return direcao_atual
