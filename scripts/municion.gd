extends Area2D

## CAJA DE MUNICIÓN tirada en el piso.
## Cuando el jugador la toca le suma balas a la reserva, larga un efecto de
## partículas y desaparece. También la sueltan algunos zombies al morir.

@export var cantidad: int = 15

@onready var sprite: Sprite2D = $Sprite2D
@onready var sonido: AudioStreamPlayer2D = $Sonido
@onready var particulas: CPUParticles2D = $Particulas

var recogida: bool = false


func _ready() -> void:
	$Label.text = "+%d" % cantidad


func _on_body_entered(body: Node2D) -> void:
	if recogida or not body is Jugador or not body.esta_vivo:
		return
	recogida = true
	body.agregar_municion(cantidad)

	# efecto: partículas doradas + sonido, y después se borra sola
	sprite.hide()
	$Label.hide()
	particulas.emitting = true
	sonido.play()
	set_deferred("monitoring", false)
	await get_tree().create_timer(0.8).timeout
	queue_free()
