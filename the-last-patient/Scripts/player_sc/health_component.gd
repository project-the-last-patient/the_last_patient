extends Node
class_name HealthComponent

signal on_death
signal on_damage(current_health)

@export var max_health: int = 3
var current_health: int

func _ready():
	current_health = max_health

func take_damage(amount: int):
	current_health -= amount
	emit_signal("on_damage", current_health)
	
	if current_health <= 0:
		emit_signal("on_death")
		
func take_life(amount : int):
	current_health += amount
	
	if current_health > max_health:
		current_health = max_health
	
	emit_signal("on_damage", current_health)
