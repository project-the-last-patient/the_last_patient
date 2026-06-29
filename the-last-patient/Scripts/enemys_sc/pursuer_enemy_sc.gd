extends CharacterBody2D

enum Estado { PATRULHANDO, CACANDO, ATACANDO, STUNADO }
var estado_atual = Estado.PATRULHANDO

# --- Referências ---
@onready var anim_sprite = $AnimatedSprite2D
@onready var hitbox = $HitBox
@onready var patrol_component = $PatrolComponent
@onready var health_comp: HealthComponent = $HealthComponent
@onready var collision = $CollisionShape2D
@onready var nav_agent = $NavigationAgent2D # Essencial para o Top-Down desviar de paredes

# --- Configurações de Movimento ---
@export var chase_speed := 130.0
@export var dash_speed := 300.0
@export var stun_duration := 2.5

# --- Sistema da Mente & Alvo ---
var ultima_posicao_player: Vector2
var recebendo_info_mente: bool = false
var tempo_na_area_target: float = 0.0
var direcao_ataque := Vector2.ZERO

var is_dead := false
var _is_ready_for_physics := false

func _ready():
	add_to_group("enemies")
	
	if hitbox and not hitbox.body_entered.is_connected(_on_hit_box_body_entered):
		hitbox.body_entered.connect(_on_hit_box_body_entered)
	
	_set_hitbox_enabled(false)
	anim_sprite.play("run")
	
	await get_tree().physics_frame
	_is_ready_for_physics = true
	
	# Conecta o sinal do PatrolComponent para ativar a caça
	if patrol_component:
		patrol_component.player_avistado.connect(_on_player_avistado_pela_patrulha)

func _on_player_avistado_pela_patrulha(pos_player: Vector2):
	if estado_atual == Estado.PATRULHANDO:
		print("Monstro avistou o player por conta própria!")
		ultima_posicao_player = pos_player
		estado_atual = Estado.CACANDO

func _physics_process(delta):
	if not _is_ready_for_physics or is_dead:
		return
	
	match estado_atual:
		Estado.PATRULHANDO:
			patrol_component.process_patrol(self, delta) # Seu componente de patrulha original
			_update_animation(velocity)
			
		Estado.CACANDO:
			_process_chase(delta)
			
		Estado.ATACANDO:
			_process_attack_dash(delta)
			
		Estado.STUNADO:
			# Fica parado no lugar
			velocity = Vector2.ZERO
			move_and_slide()

# ----------------------------------------
# 🧠 LÓGICA DA MENTE E PERSEGUIÇÃO

func receber_posicao_mente(pos_player: Vector2):
	ultima_posicao_player = pos_player
	recebendo_info_mente = true
	estado_atual = Estado.CACANDO
	tempo_na_area_target = 0.0
	# Chame sua função de spawn fora da tela aqui se necessário

func _process_chase(delta):
	var player = get_tree().get_first_node_in_group("player")
	
	if recebendo_info_mente:
		if checar_player_na_area_target():
			tempo_na_area_target += delta
			if tempo_na_area_target >= 3.0:
				recebendo_info_mente = false # Corta o sinal da mente após 3s de contato visual
		
		if is_instance_valid(player):
			ultima_posicao_player = player.global_position

	# Movimentação Top-Down usando NavigationAgent2D
	nav_agent.target_position = ultima_posicao_player
	
	if not nav_agent.is_navigation_finished():
		var proxima_posicao = nav_agent.get_next_path_position()
		var direcao = global_position.direction_to(proxima_posicao)
		velocity = direcao * chase_speed
		move_and_slide()
		_update_animation(velocity)
	else:
		# Se chegou na última posição e não vê o player, volta a patrulhar
		if not checar_player_na_area_target():
			estado_atual = Estado.PATRULHANDO
			velocity = Vector2.ZERO
	
	# Condição para ATACAR: Se estiver perto o suficiente do player real
	if is_instance_valid(player):
		var distancia_player = global_position.distance_to(player.global_position)
		if distancia_player < 80.0 and checar_player_na_area_target():
			iniciar_ataque(player.global_position)

# ----------------------------------------
# 🦷 MECÂNICA DE AVANÇO (DASH) E STUN

func iniciar_ataque(posicao_alvo: Vector2):
	estado_atual = Estado.ATACANDO
	# Calcula a direção fixa em 8 direções para o avanço
	direcao_ataque = global_position.direction_to(posicao_alvo).normalized()
	
	anim_sprite.play("attack")
	_set_hitbox_enabled(true)
	
	# Timer de segurança: Se não bater em nada, cancela o ataque após 0.5 segundos
	get_tree().create_timer(0.5).timeout.connect(func():
		if estado_atual == Estado.ATACANDO:
			encerrar_ataque()
	)

func _process_attack_dash(delta):
	velocity = direcao_ataque * dash_speed
	
	# move_and_slide() retorna true se colidir com algo
	var colidiu = move_and_slide()
	
	# Se colidir com uma parede durante o avanço, fica stunado
	if colidiu and is_on_wall():
		aplicar_stun()

func aplicar_stun():
	estado_atual = Estado.STUNADO
	_set_hitbox_enabled(false)
	anim_sprite.play("idle") # Coloque uma animação de tonto aqui se tiver
	modulate = Color.YELLOW # Feedback visual de Stun
	
	await get_tree().create_timer(stun_duration).timeout
	
	modulate = Color.WHITE
	# Após o stun, tenta reavaliar se continua caçando ou volta a patrulhar
	if checar_player_na_area_target():
		estado_atual = Estado.CACANDO
	else:
		estado_atual = Estado.PATRULHANDO

func encerrar_ataque():
	_set_hitbox_enabled(false)
	if estado_atual == Estado.ATACANDO:
		estado_atual = Estado.CACANDO

# ----------------------------------------
# 🎯 DETECÇÃO & AUXILIARES

func checar_player_na_area_target() -> bool:
	# Certifique-se de criar a AreaVisao separada como conversamos,
	# ou se mantiver na HitBox, use: var corpos = hitbox.get_overlapping_bodies()
	var corpos = hitbox.get_overlapping_bodies()
	for corpo in corpos:
		if corpo.is_in_group("player"):
			return true
	return false

func _on_hit_box_body_entered(body):
	if body.is_in_group("player"):
		print("Monstro acertou o player! Tentando causar dano no HealthComponent.")
		
		# Procura o HealthComponent dentro do nó do Player
		var player_health = body.get_node_or_null("HealthComponent")
		
		if player_health:
			player_health.take_damage(1) # Aplica 1 de dano usando o seu componente!
		elif body.has_method("take_damage"):
			body.take_damage(1) # Backup caso o método esteja direto no player
		
		# Se acertou o player, cancela o avanço rápido (dash) e volta a caçar normal
		if estado_atual == Estado.ATACANDO:
			call_deferred("encerrar_ataque")

func _set_hitbox_enabled(enabled: bool):
	for shape in hitbox.get_children():
		if shape is CollisionShape2D:
			shape.set_deferred("disabled", not enabled)

# ----------------------------------------
# 🎞️ ANIMAÇÃO 8 DIREÇÕES (BASEADO EM VETOR)

func _update_animation(dir: Vector2):
	if dir.length() > 0.1:
		anim_sprite.play("run")
		anim_sprite.flip_h = dir.x < 0
	else:
		anim_sprite.play("idle")

# ----------------------------------------
# ❤️ VIDA E MORTE (Mantidos e adaptados do seu original)

	if collision:
		collision.set_deferred("disabled", true)
	_set_hitbox_enabled(false)
	
