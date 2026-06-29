extends CharacterBody2D

# --- REFERÊNCIAS AOS COMPONENTES ---
@onready var movement_comp: MovementComponent = $Components/MovementComponent
@onready var anim_comp: AnimationComponent = $Components/AnimationComponent
@onready var health_comp: HealthComponent = $Components/HealthComponent
@onready var shoot_comp: ShootComponent = $Components/ShootComponent
@onready var energy_comp: EnergyComponent = $Components/EnergyComponent
@onready var weapon_sprite: Sprite2D = $anim/WeaponSprite

# --- REFERÊNCIAS VISUAIS/UI ---
@onready var hud = $Components/HUD
@onready var camera: Camera2D = $Camera2D

func _ready():
	equip_weapon(shoot_comp.weapon)
	# já existente (vida)
	health_comp.on_damage.connect(_on_damage_received)
	health_comp.on_death.connect(_on_death)
	
	# 🔋 energia
	if energy_comp:
		energy_comp.energy_changed.connect(_on_energy_changed)
	
	# inicializa HUD
	if hud:
		hud.init_health(health_comp.max_health, health_comp.current_health)
		hud.init_energy(energy_comp.max_energy, energy_comp.current_energy)
func _on_energy_changed(current_energy):
	if hud:
		hud.update_energy(current_energy)

func equip_weapon(new_weapon: WeaponData):
	shoot_comp.weapon = new_weapon
	
	if weapon_sprite and new_weapon.weapon_texture:
		weapon_sprite.texture = new_weapon.weapon_texture
		
func _physics_process(delta: float) -> void:
	if Input.is_action_pressed("collect"):
		suck_particles()
		
	handle_taunt_logic(delta)
	
	# 1. Inputs Básicos
	var input_direction := Input.get_axis("move_left", "move_right")
	if Input.is_action_pressed("shoot"):
		var dir = -1 if movement_comp.should_flip_h else 1
		shoot_comp.shoot(dir)
	
	# 4. Movimento (Andar, Pular, Parede)
	movement_comp.process_movement(self, input_direction, delta)
	
	# 5. Aplica a Física
	move_and_slide()
	
	# 6. Animação
	# Passamos todas as variáveis que a animação precisa saber
	anim_comp.handle_move_animation(
		velocity, 
		is_on_floor(), 
		movement_comp.is_wall_sliding,
		movement_comp.should_flip_h,
		movement_comp.is_dashing
		
	)

# --- SISTEMA DE VIDA E DANO ---
func suck_particles():
	
	var particles = get_tree().get_nodes_in_group("energy_particles")
	
	for p in particles:
		var dist = global_position.distance_to(p.global_position)
		
		if dist < 200:
			p.start_sucking(self)
			
# Esta é a função pública que os Inimigos chamam: body.take_damage(1)
func take_damage(amount: int):
	modulate = Color.DARK_RED
	await get_tree().create_timer(0.1).timeout
	modulate = Color.WHITE
	await get_tree().create_timer(0.1).timeout
	modulate = Color.DARK_RED
	await get_tree().create_timer(0.1).timeout
	modulate = Color.WHITE
	health_comp.take_damage(amount)

func take_life(amount: int):
	modulate = Color.GREEN_YELLOW
	await get_tree().create_timer(0.1).timeout
	modulate = Color.WHITE
	await get_tree().create_timer(0.1).timeout
	modulate = Color.GREEN_YELLOW
	await get_tree().create_timer(0.1).timeout
	modulate = Color.WHITE
	health_comp.take_life(amount)

# O componente avisou que a vida mudou (Sinal on_damage)
func _on_damage_received(current_health):
	print("Player tomou dano! Vida restante: ", current_health)
	
	# 1. Atualiza a HUD (Barra de Vida)
	if hud:
		hud.update_health(current_health)
	
	# 2. Feedback Visual (Piscar Vermelho)
	modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	modulate = Color.WHITE
	

func _on_death():
	print("GAME OVER")
	
	# Trava o personagem
	set_physics_process(false)
	
	# Opcional: Tocar animação de morte aqui
	# anim_comp.play_action("death")
	
	await get_tree().create_timer(2.0).timeout
	get_tree().reload_current_scene()

# --- FUNÇÕES DE PONTE (BRIDGE) ---

# O CombatComponent chama isso quando a Kunai gruda na parede.
# O Player serve de ponte para avisar o MovementComponent.
func enter_wall_cling(normal: Vector2):
	movement_comp.enter_wall_cling(self, normal)

# --- LÓGICA DE VISUAL E EXTRAS ---

func handle_taunt_logic(delta):
	# Se apertar o botão e estiver no chão
	if Input.is_action_just_pressed("taunt") and is_on_floor():
		anim_comp.play_action("taunt")
		velocity.x = 0 # Para o boneco imediatamente
	
	# Lógica do Zoom da Câmera durante o Taunt
	if camera:
		var is_taunting = (anim_comp.sprite.animation == "taunt" and anim_comp.sprite.is_playing())
		
		var target_zoom = Vector2(5.0, 5.0) # Zoom normal (ajuste conforme seu jogo)
		
		if is_taunting:
			target_zoom = Vector2(6.5, 6.5) # Zoom IN (Bem perto)
		
		# Faz a transição suave do zoom (Lerp)
		camera.zoom = camera.zoom.lerp(target_zoom, 5.0 * delta)


func _on_kill_zone_body_entered(body: Node2D) -> void:
	pass # Replace with function body.
