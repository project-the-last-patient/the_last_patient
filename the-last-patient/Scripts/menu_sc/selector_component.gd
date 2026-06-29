extends Control # Mude de Node2D para Control

@export var group_name: String = "MenuButtons"
@export var smooth_movement: bool = true
@export var speed: float = 15.0

var buttons: Array[Node] = []
var current_index: int = 0

func _ready():
	await get_tree().process_frame
	update_buttons_list()
	update_position()

func _input(event):
	if buttons.is_empty(): return

	if event.is_action_pressed("ui_up"):
		change_selection(-1)
	elif event.is_action_pressed("ui_down"):
		change_selection(1)

func update_buttons_list():
	buttons = get_tree().get_nodes_in_group(group_name)
	# Ordena os botões de cima para baixo
	buttons.sort_custom(func(a, b): return a.global_position.y < b.global_position.y)

func change_selection(amount: int):
	# Pegamos o total de botões
	var total_buttons = buttons.size()
	if total_buttons == 0: return
	
	# O segredo está no operador de módulo (%)
	# (index + deslocamento + total) % total garante que o número sempre 
	# fique entre 0 e o máximo, voltando ao início ou fim se necessário.
	current_index = (current_index + amount + total_buttons) % total_buttons
	
	if not smooth_movement:
		update_position()
func _process(delta):
	if smooth_movement and not buttons.is_empty():
		var target_pos = _get_target_center(buttons[current_index])
		# No Control, usamos global_position também, mas o comportamento de âncoras afeta o nó pai
		global_position = global_position.lerp(target_pos, speed * delta)

func update_position():
	if buttons.is_empty(): return
	global_position = _get_target_center(buttons[current_index])

func _get_target_center(label: Control) -> Vector2:
	# 1. Pega a posição global do Label
	var target_x = label.global_position.x + (label.size.x / 2)
	
	# 2. Define o Y para a base do Label
	# Você pode somar um pequeno valor (ex: + 5) para dar um distanciamento
	var target_y = label.global_position.y + label.size.y
	
	# 3. Subtrai metade do tamanho do próprio seletor (se for Control) 
	# para que o centro dele bata com o centro do Label
	return Vector2(target_x, target_y) - (size / 2)
