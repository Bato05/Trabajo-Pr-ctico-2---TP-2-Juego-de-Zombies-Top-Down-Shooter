extends Sprite2D

## Mancha de sangre que queda en el piso. Elige una textura al azar.

const TEXTURAS = [
	preload("res://assets/sprites/efectos/sangre_1.png"),
	preload("res://assets/sprites/efectos/sangre_2.png"),
	preload("res://assets/sprites/efectos/sangre_3.png"),
]


func _ready() -> void:
	texture = TEXTURAS.pick_random()
	rotation = randf() * TAU
	var tamanio = randf_range(0.7, 1.1)
	scale = Vector2.ZERO
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(tamanio, tamanio), 0.25)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
