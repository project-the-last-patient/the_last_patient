extends Node
class_name GlobalInventoryComponent

signal inv_updated(categoria: String)

# O "Excel": Cada chave é uma coluna, cada valor é a lista de itens
var storage = {
	"heal": [],
	"keys": []
}

@export var max_cartas: int = 3
# Coletáveis geralmente não têm limite, então deixamos crescer livremente

func _ready() -> void:
	storage["heal"].resize(max_cartas)
	storage["heal"].fill(null)

## Função Única para adicionar qualquer coisa
## categoria: "cartas" ou "coletaveis"
func add_to_storage(categoria: String, item_data: Dictionary) -> bool:
	if not storage.has(categoria):
		print("Erro: Categoria ", categoria, " não existe!")
		return false
	
	var lista = storage[categoria]
	
	# Lógica para CARTAS (Com limite de slots)
	if categoria == "heal":
		var slot_livre = lista.find(null)
		if slot_livre != -1:
			lista[slot_livre] = item_data
			emitir_update(categoria, item_data)
			return true
		print("Vida esta cheia!")
		return false
	
	# Lógica para COLETÁVEIS (Sem limite, apenas adiciona no final)
	else:
		lista.append(item_data)
		emitir_update(categoria, item_data)
		return true

func emitir_update(categoria: String, item_data: Dictionary):
	print("Item adicionado em [", categoria, "]: ", item_data.get("nome", "ID:" + str(item_data.id)))
	inv_updated.emit(categoria)

## Função para a Caixa de Correio buscar especificamente em uma categoria
func remover_por_id(categoria: String, id_alvo: int) -> bool:
	if not storage.has(categoria): return false
	
	var lista = storage[categoria]
	for i in range(lista.size()):
		if lista[i] != null and lista[i].get("id") == id_alvo:
			if categoria == "keys":
				lista[i] = null # Cartas deixam slot vazio
			else:
				lista.remove_at(i) # Coletáveis apenas somem da lista
			
			inv_updated.emit(categoria)
			return true
	return false
