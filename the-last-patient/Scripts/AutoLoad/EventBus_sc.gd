extends Node

# Sinal global que envia o ID da porta que deve ser destrancada
@warning_ignore("unused_signal")
signal door_unlocked(door_id: String)
