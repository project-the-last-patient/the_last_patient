extends CanvasLayer

@onready var life_bar = $LifeBar
@onready var energy_bar = $PowerBar

func _ready():
	# Zera a barra ou enche ela no começo, dependendo do que você quer
	pass

# Função para configurar a vida máxima no início do jogo
func init_health(max_health: int, current_health: int):
	life_bar.max_value = max_health
	life_bar.value = current_health

# Função que será chamada sempre que tomar dano
func update_health(new_health: int):
	life_bar.value = new_health
	
func init_energy(max_energy: int, current_energy: int):
	energy_bar.max_value = max_energy
	energy_bar.value = current_energy

func update_energy(new_energy: int):
	energy_bar.value = new_energy
