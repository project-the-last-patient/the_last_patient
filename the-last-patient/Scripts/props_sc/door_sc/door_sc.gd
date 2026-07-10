extends Node2D

# --- SINAIS ---
signal door_opened
signal door_closed
signal trigger_activated
signal next_level_reached

# --- VARIÁVEIS EXPORTADAS (INSPECTOR) ---
@export_group("Configurações Básicas")
@export var action_button: String = "action_button"
@export var rotation_speed: float = 5.0
@export var orientation_node: Node2D = null 

@export_group("Gatilhos")
@export var is_triggered: bool = false

@export_group("Trancamento")
@export var need_key: bool = false
@export var key_item: Node = null
@export var door_id: String = ""

@export_group("Teletransporte")
@export var need_tp: bool = false
@export var destination_scene: PackedScene
@export var tp_position: Vector2 = Vector2.ZERO
@export var tp_rotation: float = 0.0

@export_group("Mudança de Fase")
@export var next_level_door: bool = false

# --- VARIÁVEIS INTERNAS ---
var is_open: bool = false
var target_rotation: float = 0.0
var player_in_range: Node2D = null

func _ready() -> void:
	if not orientation_node:
		orientation_node = get_node_or_null("Orientation") as Node2D
	
	if orientation_node:
		target_rotation = orientation_node.rotation
	else:
		push_error("Erro: O script precisa de um nó Node2D de Orientação/Dobradiça.")

	var area = get_node_or_null("Orientation/Sprite2D/Area2D")
	if area:
		area.body_entered.connect(_on_area_2d_body_entered)
		area.body_exited.connect(_on_area_2d_body_exited)

	if need_key and key_item:
		if key_item.has_signal("unique"):
			key_item.unique.connect(_on_key_unlocked)
	elif need_key and not key_item:
		EventBusSc.door_unlocked.connect(_on_global_door_unlocked)

func _process(delta: float) -> void:
	if orientation_node:
		orientation_node.rotation = rotate_toward(orientation_node.rotation, target_rotation, rotation_speed * delta)

# --- DETECÇÃO DO BOTÃO DE AÇÃO (APENAS PLAYER) ---
func _unhandled_input(event: InputEvent) -> void:
	if player_in_range and event.is_action_pressed(action_button):
		interact(player_in_range)

# --- FUNÇÃO PRINCIPAL DE INTERAÇÃO DO PLAYER ---
func interact(player: Node2D) -> void:
	if need_key:
		print("A porta está trancada.")
		return 

	if next_level_door:
		next_level_reached.emit()
		return

	if need_tp:
		teleport_entity(player)
		return

	toggle_door()

# --- NOVA FUNÇÃO: INTERAÇÃO DO MONSTRO ---
# --- FUNÇÃO DE INTERAÇÃO DO MONSTRO ATUALIZADA ---
func monster_interact(monster: CharacterBody2D) -> void:
	# 1. Se precisar de chave, o monstro é completamente bloqueado
	if need_key:
		print("[Porta] ", name, " está trancada. O monstro não consegue interagir.")
		return

	# 2. Se for uma porta de mudança de fase, o monstro ignora
	if next_level_door:
		return

	# 3. Se a porta tiver Teletransporte, teletransporta o monstro direto
	if need_tp:
		teleport_entity(monster)
		return

	# 4. COMPORTAMENTO DE ABRIR/FECHAR LIVREMENTE:
	# Para evitar que o monstro fique abrindo e fechando a porta no mesmo frame 
	# devido ao process_patrol rodar muito rápido, criamos uma pequena trava de tempo de 1.5 segundos
	if not has_meta("monster_cooldown"):
		set_meta("monster_cooldown", false)
		
	if get_meta("monster_cooldown") == true:
		return # Se estiver no cooldown, ignora o comando por enquanto

	# Inverte o estado da porta (Abre se fechada, Fecha se aberta)
	toggle_door()
	
	if is_open:
		print("[Porta] Monstro ABRU a porta: ", name)
	else:
		print("[Porta] Monstro FECHOU a porta: ", name)

	# Ativa o cooldown para o monstro não "espamar" a porta
	set_meta("monster_cooldown", true)
	await get_tree().create_timer(1.5).timeout
	set_meta("monster_cooldown", false)

# --- LÓGICA DE ABERTURA E FECHAMENTO ---
func toggle_door() -> void:
	if not is_open:
		target_rotation += deg_to_rad(90)
		is_open = true
		door_opened.emit()
		if is_triggered:
			trigger_activated.emit()
	else:
		target_rotation -= deg_to_rad(90)
		is_open = false
		door_closed.emit()

# --- LÓGICA DE TELETRANSPORTE (MODIFICADA PARA 'ENTITY' PLAYER OU MONSTRO) ---
func teleport_entity(entity: Node2D) -> void:
	if destination_scene:
		# Se mudar de cena por PackedScene, o monstro some junto com o mapa antigo
		get_tree().change_scene_to_packed(destination_scene)
	else:
		# Teleporta o Player ou o Monstro dentro do mesmo mapa
		entity.global_position = tp_position
		entity.global_rotation = deg_to_rad(tp_rotation)
		door_opened.emit()

func _on_key_unlocked() -> void:
	need_key = false

func _on_global_door_unlocked(unlocked_door_id: String) -> void:
	if door_id == "": return
	if unlocked_door_id == door_id:
		need_key = false

# --- SINAIS DA AREA2D ---
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") or body.name == "Player":
		player_in_range = body

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body == player_in_range:
		player_in_range = null
