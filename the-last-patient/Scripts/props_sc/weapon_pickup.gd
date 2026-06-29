extends Area2D

var weapon: WeaponData

@onready var sprite: Sprite2D = $Sprite2D

func _ready():
	if weapon:
		_apply_weapon_visual()

func set_weapon(w: WeaponData):
	weapon = w
	
	# se já estiver pronto, aplica na hora
	if is_inside_tree():
		_apply_weapon_visual()

func _apply_weapon_visual():
	if sprite == null:
		print("❌ sprite não encontrado")
		return
	
	if weapon.weapon_texture:
		sprite.texture = weapon.weapon_texture
	

func _on_body_entered(body):
	if body.is_in_group("player"):
		body.equip_weapon(weapon)
		queue_free()
