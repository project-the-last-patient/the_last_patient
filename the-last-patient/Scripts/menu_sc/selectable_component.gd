extends Node # Ou Control, dependendo de como você estruturou o componente
@export_file("*.tscn") var target_scene: String
@onready var area_2d: Area2D = $Area2D # Certifique-se que o nome do nó é este

func _process(_delta):
	# Chamamos a função can_select a cada frame para verificar a interação
	if can_select():
		_on_selected()

func can_select() -> bool:
	# 1. Verifica se a tecla de aceitar foi pressionada
	if Input.is_action_just_pressed("ui_accept"):
		
		# 2. Verifica se há sobreposição de áreas
		var overlapping_areas = area_2d.get_overlapping_areas()
		
		for area in overlapping_areas:
			# 3. Verifica se a área com a qual colidimos pertence ao SelectorComponent
			# Você pode verificar pelo nome do script ou por um grupo
			if area.owner.name == "SelectorComponent" or area.owner.is_in_group("Selector"):
				print("SUCESSO: [", get_parent().name, "] foi selecionado pelo SelectorComponent!")
				return true
				
	return false
func _on_selected():
	if target_scene != "":
		get_tree().change_scene_to_file(target_scene)
	else:
		print("Erro: Nenhuma cena definida")
