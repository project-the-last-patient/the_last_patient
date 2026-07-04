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
	# 1. Checa a presença do player
	_checar_presenca_do_player(body)
	
	# 2. Interagir com portas
	if body.is_on_wall():
		print("[PatrolComponent] Inimigo bateu na parede durante a patrulha.")
		_tentar_interagir_com_portas(body)
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
	print("[PatrolComponent] Novo destino aleatório definido em: ", destino_atual)

func _esperar_no_ponto(body: CharacterBody2D):
	print("[PatrolComponent] Iniciando tempo de espera no ponto...")
	aguardando = true
	body.velocity = Vector2.ZERO
	
	await get_tree().create_timer(tempo_espera_ponto).timeout
	
	aguardando = false
	print("[PatrolComponent] Tempo de espera finalizado.")
	definir_novo_destino_aleatorio(body)

# --- INTERAÇÃO COM O CENÁRIO (PORTAS) ---

func _tentar_interagir_com_portas(body: CharacterBody2D):
	var hitbox = body.get_node_or_null("HitBox")
	if hitbox:
		var areas = hitbox.get_overlapping_areas()
		for area in areas:
			if area.is_in_group("Portas") or area.has_method("abrir_porta"):
				if area.has_method("abrir_porta"):
					area.abrir_porta()
					print("[PatrolComponent] Monstro abriu uma porta no caminho: ", area.name)

# --- DETECÇÃO DO JOGADOR ---

func _checar_presenca_do_player(body: CharacterBody2D):
	var fov = body.get_node_or_null("FOV")
	
	if not fov:
		# Se printar isso, significa que o script não achou o nó FOV no Pursuer
		print("[DEBUG FOV] ERRO: Nó chamado 'FOV' não foi encontrado dentro de: ", body.name)
		return
		
	var corpos_no_fov = fov.get_overlapping_bodies()
	
	# Só printa se o FOV estiver detectando alguma coisa, para não floodar o console vazio
	if corpos_no_fov.size() > 0:
		print("[DEBUG FOV] Lista de corpos que o FOV está tocando neste frame:")
		for corpo in corpos_no_fov:
			print(" -> Tocando em: ", corpo.name, " | Grupos do corpo: ", corpo.get_groups())
			
			if corpo.is_in_group("Player"):
				print("[DEBUG FOV] 🔥 SUCESSO! Player detectado no grupo. Emitindo sinal 'player_avistado'.")
				player_avistado.emit(corpo.global_position)
				break

func get_facing_direction() -> Vector2:
	return direcao_atual
