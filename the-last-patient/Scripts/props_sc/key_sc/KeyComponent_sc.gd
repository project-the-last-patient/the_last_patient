extends Node2D

@export var fade_out: bool = false
@export var Unique: bool = false
@export var target_door_id: String = ""

signal unique

# MUDANÇA AQUI: O nó Area2D precisa estar conectado ao sinal 'body_entered'
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") or body.name == "Player":
		collect_key()
		
func collect_key() -> void:
	EventBus.door_unlocked.emit(target_door_id)
	print("Sinal de destrancar enviado para a porta: ", target_door_id)
	
	if fade_out:
		queue_free() # Remove a chave do mapa
	if Unique:
		unique.emit()
		print("Chave coletada!")
