

extends CharacterBody2D

enum Estado { PATRULHANDO, CACANDO, ATACANDO, STUNADO }
var estado_atual = Estado.PATRULHANDO

# --- Referências ---
@onready var anim_sprite = $AnimatedSprite2D
@onready var hitbox = $HitBox
@onready var patrol_component = $PatrolComponent
@onready var collision = $CollisionShape2D
@onready var nav_agent = $NavigationAgent2D

# --- Configurações de Movimento ---
@export var chase_speed := 55.0
@export var dash_speed := 100.0
@export var stun_duration := 1.5

# --- Sistema da Mente & Alvo ---
var ultima_posicao_player: Vector2
var recebendo_info_mente: bool = false
var tempo_na_area_target: float = 0.0
var direcao_ataque := Vector2.ZERO

var is_dead := false
var _is_ready_for_physics := false

func _ready():
	print("[Pursuer] Inicializando e adicionando ao grupo 'enemies'.")
	add_to_group("enemies")
	
	if hitbox and not hitbox.body_entered.is_connected(_on_hit_box_body_entered):
		hitbox.body_entered.connect(_on_hit_box_body_entered)
	
	_set_hitbox_enabled(false)
	anim_sprite.play("run")
	
	# 🔥 Garante que o mapa do TileSet carregou na memória antes do inimigo agir
	await get_tree().physics_frame
	_is_ready_for_physics = true
	print("[Pursuer] Pronto para processar física e navegação.")
	
	# Mude isso no seu _ready():
	if patrol_component:
		# Só conecta se o sinal já não estiver conectado a essa função
		if not patrol_component.player_avistado.is_connected(_on_patrol_component_player_avistado):
			patrol_component.player_avistado.connect(_on_patrol_component_player_avistado)

func _on_patrol_component_player_avistado(player_position: Vector2) -> void:
	if estado_atual == Estado.PATRULHANDO:
		print("[Pursuer] 🔥 Sinal do componente recebido! Jogador avistado em: ", player_position)
		ultima_posicao_player = player_position
		mudar_estado(Estado.CACANDO)

func _physics_process(delta):
	if not _is_ready_for_physics or is_dead:
		return
	
	match estado_atual:
		Estado.PATRULHANDO:
			patrol_component.process_patrol(self, delta)
			_update_animation(velocity)
			
		Estado.CACANDO:
			_process_chase(delta)
			
		Estado.ATACANDO:
			_process_attack_dash(delta)
			
		Estado.STUNADO:
			velocity = Vector2.ZERO
			move_and_slide()

# --- GERENCIADOR DE ESTADOS (Auxiliar de Debug) ---
func mudar_estado(novo_estado: Estado):
	print("[Pursuer] Estado alterado: ", Estado.keys()[estado_atual], " -> ", Estado.keys()[novo_estado])
	estado_atual = novo_estado

# ----------------------------------------
# 🧠 LÓGICA DA MENTE E PERSEGUIÇÃO

func receber_posicao_mente(pos_player: Vector2):
	print("[Pursuer] 🧠 Posição do jogador recebida via Mente em: ", pos_player)
	ultima_posicao_player = pos_player
	recebendo_info_mente = true
	tempo_na_area_target = 0.0
	mudar_estado(Estado.CACANDO)

func _process_chase(delta):
	var player = get_tree().get_first_node_in_group("player")
	var vendo_player = checar_player_na_area_target()
	
	if recebendo_info_mente:
		if vendo_player:
			tempo_na_area_target += delta
			if tempo_na_area_target >= 3.0:
				print("[Pursuer] 🧠 Contato visual mantido por 3s. Desconectando da Mente.")
				recebendo_info_mente = false
		
		if is_instance_valid(player):
			ultima_posicao_player = player.global_position

	nav_agent.target_position = ultima_posicao_player
	
	print("[DEBUG CAÇA] Alvo definido em: ", nav_agent.target_position, " | Caminho finalizado? ", nav_agent.is_navigation_finished()) # << ADD
	
	if not nav_agent.is_navigation_finished():
		var proxima_posicao = nav_agent.get_next_path_position()
		var direcao = global_position.direction_to(proxima_posicao)
		velocity = direcao * chase_speed
		print("[DEBUG CAÇA] Velocidade calculada: ", velocity) # << ADD
		move_and_slide()
		_update_animation(velocity)
	else:
		if not vendo_player:
			print("[Pursuer] Chegou ao destino e não encontrou ninguém. Retornando para a Patrulha.")
			mudar_estado(Estado.PATRULHANDO)
			velocity = Vector2.ZERO
	
	if not nav_agent.is_navigation_finished():
		var proxima_posicao = nav_agent.get_next_path_position()
		var direcao = global_position.direction_to(proxima_posicao)
		velocity = direcao * chase_speed
		move_and_slide()
		_update_animation(velocity)
	else:
		if not vendo_player:
			print("[Pursuer] Chegou ao destino e não encontrou ninguém. Retornando para a Patrulha.")
			mudar_estado(Estado.PATRULHANDO)
			velocity = Vector2.ZERO
	
	if is_instance_valid(player):
		var distancia_player = global_position.distance_to(player.global_position)
		if distancia_player < 80.0 and vendo_player:
			iniciar_ataque(player.global_position)

# ----------------------------------------
# 🦷 MECÂNICA DE AVANÇO (DASH) E STUN

func iniciar_ataque(posicao_alvo: Vector2):
	print("[Pursuer] 🦷 Alvo no alcance (", global_position.distance_to(posicao_alvo), "px). Iniciando investida!")
	mudar_estado(Estado.ATACANDO)
	direcao_ataque = global_position.direction_to(posicao_alvo).normalized()
	
	anim_sprite.play("attack")
	_set_hitbox_enabled(true)
	
	get_tree().create_timer(0.5).timeout.connect(func():
		if estado_atual == Estado.ATACANDO:
			print("[Pursuer] Investida falhou em atingir o alvo dentro do tempo limite.")
			encerrar_ataque()
	)

func _process_attack_dash(_delta):
	velocity = direcao_ataque * dash_speed
	var colidiu = move_and_slide()
	
	if colidiu and is_on_wall():
		print("[Pursuer] 💥 Colisão violenta contra a parede durante a investida!")
		aplicar_stun()

func aplicar_stun():
	mudar_estado(Estado.STUNADO)
	_set_hitbox_enabled(false)
	anim_sprite.play("idle")
	modulate = Color.YELLOW
	
	await get_tree().create_timer(stun_duration).timeout
	
	print("[Pursuer] Efeito de tontura finalizado. Reavaliando...")
	modulate = Color.WHITE
	
	if checar_player_na_area_target():
		mudar_estado(Estado.CACANDO)
	else:
		mudar_estado(Estado.PATRULHANDO)

func encerrar_ataque():
	_set_hitbox_enabled(false)
	if estado_atual == Estado.ATACANDO:
		mudar_estado(Estado.CACANDO)

# ----------------------------------------
# 🎯 DETECÇÃO & AUXILIARES

func checar_player_na_area_target() -> bool:
	var fov = get_node_or_null("FOV")
	if fov:
		var corpos = fov.get_overlapping_bodies()
		for corpo in corpos:
			if corpo.is_in_group("player"):
				return true
	return false

func _on_hit_box_body_entered(body):
	if body.is_in_group("player"):
		print("[Pursuer] 💥 Ataque conectou! Aplicando dano à saúde do jogador.")
		var player_health = body.get_node_or_null("HealthComponent")
		
		if player_health:
			player_health.take_damage(1)
		elif body.has_method("take_damage"):
			body.take_damage(1)
		
		if estado_atual == Estado.ATACANDO:
			call_deferred("encerrar_ataque")

func _set_hitbox_enabled(enabled: bool):
	for shape in hitbox.get_children():
		if shape is CollisionShape2D:
			shape.set_deferred("disabled", not enabled)

# ----------------------------------------
# 🎞️ ANIMAÇÃO

func _update_animation(dir: Vector2):
	if dir.length() > 0.1:
		anim_sprite.play("run")
		anim_sprite.flip_h = dir.x < 0
	else:
		anim_sprite.play("idle")
