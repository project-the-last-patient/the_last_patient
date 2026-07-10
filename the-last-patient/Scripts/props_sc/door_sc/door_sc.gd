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
@export var orientation_node: Node2D = null # Arraste o seu nó 'Orientation' / 'EixoDobradica' aqui!

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
	# Se você esqueceu de arrastar o nó no Inspector, ele tenta achar pelo nome padrão
	if not orientation_node:
		orientation_node = get_node_or_null("Orientation") as Node2D
	
	# Agora definimos a rotação inicial baseada no nó de orientação, não na raiz!
	if orientation_node:
		target_rotation = orientation_node.rotation
	else:
		push_error("Erro: O script precisa de um nó Node2D de Orientação/Dobradiça para girar corretamente.")

	# Conecta a Area2D automaticamente
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
	# Rotaciona apenas o nó de orientação/dobradiça de forma suave
	if orientation_node:
		orientation_node.rotation = rotate_toward(orientation_node.rotation, target_rotation, rotation_speed * delta)

# --- DETECÇÃO DO BOTÃO DE AÇÃO ---
func _unhandled_input(event: InputEvent) -> void:
	if player_in_range and event.is_action_pressed(action_button):
		interact(player_in_range)

# --- FUNÇÃO PRINCIPAL DE INTERAÇÃO ---
func interact(player: Node2D) -> void:
	# CORREÇÃO 1: A chave AGORA é a prioridade máxima!
	# Se precisar de chave e ainda estiver trancada, bloqueia QUALQUER outra ação (TP, abrir, etc)
	if need_key:
		print("A porta está trancada. Encontre a chave ou ative o gatilho primeiro!")
		return 

	# Se passou pela chave (ou não precisa), o resto funciona:
	if next_level_door:
		next_level_reached.emit()
		return

	if need_tp:
		teleport_player(player)
		return

	# Comportamento padrão de abrir/fechar se não for TP ou Mudança de Fase
	toggle_door()

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

# --- LÓGICA DE TELETRANSPORTE ---
func teleport_player(player: Node2D) -> void:
	if destination_scene:
		get_tree().change_scene_to_packed(destination_scene)
	else:
		player.global_position = tp_position
		player.global_rotation = deg_to_rad(tp_rotation)
		door_opened.emit()

func _on_key_unlocked() -> void:
	need_key = false
	print("Porta destrancada! Agora você pode interagir com ela.")

# --- SINAIS DA AREA2D ---
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") or body.name == "Player":
		player_in_range = body

func _on_area_2d_body_exited(body: Node2D) -> void:
	if body == player_in_range:
		player_in_range = null
		
func _on_global_door_unlocked(unlocked_door_id: String) -> void:
	# 1. Se o ID da porta estiver vazio no Inspector, avisa o desenvolvedor e não faz nada
	if door_id == "":
		push_warning("Aviso: Esta porta precisa de chave, mas você esqueceu de digitar um 'door_id' no Inspector!")
		return

	# 2. Só destranca se o ID transmitido for exatamente igual ao ID desta porta
	if unlocked_door_id == door_id:
		need_key = false
		print("A porta [", door_id, "] foi destrancada globalmente!")
	else:
		print("Sinal recebido para a porta '", unlocked_door_id, "', mas o ID desta porta é '", door_id, "'. Ignorando.")
