extends Node2D

## PUERTA - el nodo raíz es la BISAGRA. La hoja (AnimatableBody2D) mide 64 px
## hacia +X. Se abre sola cuando el jugador o un zombie entra al sensor,
## girando hacia el lado contrario de quien la empuja.
## Si el JUGADOR la abre y hay zombies del otro lado, los aturde
## (el clásico "portazo" de Hotline Miami).
##
## Para una pared vertical, rotá la puerta 90° en el editor.

@export var angulo_apertura: float = 95.0
@export var duracion_apertura: float = 0.16
@export var segundos_aturdimiento: float = 2.0

@onready var hoja: AnimatableBody2D = $Hoja
@onready var sonido: AudioStreamPlayer2D = $Sonido

var abierta: bool = false


func _on_sensor_body_entered(body: Node2D) -> void:
	if abierta:
		return
	if body is Jugador or body is Enemigo:
		abrir(body)


func abrir(quien: Node2D) -> void:
	abierta = true
	# ¿de qué lado de la puerta viene? (Y local negativa = "arriba")
	var lado_de_quien = sign(to_local(quien.global_position).y)
	if lado_de_quien == 0:
		lado_de_quien = -1
	var lado_de_apertura = -lado_de_quien
	var destino = deg_to_rad(angulo_apertura) * lado_de_apertura

	sonido.play()
	var tween = create_tween()
	tween.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.tween_property(hoja, "rotation", destino, duracion_apertura)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Una vez abierta, la hoja queda pegada al borde del hueco: si siguiera siendo
	# sólida, el jugador y los zombies (que siguen la navegación, donde la puerta
	# no existe) se engancharían en ella al pasar en diagonal. Por eso, al
	# terminar de abrirse, deja de chocar (sigue viéndose).
	tween.tween_callback(func(): hoja.get_node("CollisionShape2D").set_deferred("disabled", true))

	if quien is Jugador:
		_portazo(lado_de_apertura)


## Aturde a los zombies que estén en la zona donde barre la hoja
func _portazo(lado: float) -> void:
	for zombie in get_tree().get_nodes_in_group("enemigos"):
		if not zombie.esta_vivo:
			continue
		var local = to_local(zombie.global_position)
		var en_el_barrido = local.x > -16 and local.x < 84 and sign(local.y) == lado and abs(local.y) < 80
		if en_el_barrido:
			var direccion = (zombie.global_position - global_position).normalized()
			zombie.aturdir(segundos_aturdimiento, direccion)
