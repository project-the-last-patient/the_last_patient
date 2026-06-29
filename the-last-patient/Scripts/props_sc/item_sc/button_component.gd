extends Node

@export var is_active: bool = false
@export var active_color: Color = Color.GREEN
@export var inactive_color: Color = Color.RED

signal toggled(new_state: bool)

# Usar % permite que a Godot ache o nó mesmo se você mudar a estrutura depois
@onready var rect_node = %ButtonSprite
@onready var area_node = %TriggerBotton

func _ready():
	if area_node:
		area_node.body_entered.connect(_on_body_entered)
		print("Conectado com sucesso via Unique Name!")
	else:
		print("Erro: Não encontrei o nó %TriggerBotton")
	
	_update_visual()

func _on_body_entered(body):
	if body.is_in_group("player") or body.name == "Player":
		toggle_button()

func toggle_button():
	is_active = !is_active
	toggled.emit(is_active)
	_update_visual()
	print("Botão: ", is_active)

func _update_visual():
	if rect_node:
		rect_node.color = active_color if is_active else inactive_color
