extends EstadoJugador

## IDLE: quieto, pero puede apuntar, disparar y recargar.

func start() -> void:
	jugador.anim_cuerpo.play("idle")


func on_physics_process(delta: float) -> void:
	jugador.apuntar()
	var direccion = jugador.leer_direccion()
	jugador.mover(delta, direccion)

	if procesar_arma():
		return
	if direccion != Vector2.ZERO:
		state_machine.change_to(NombresEstadosJugador.MOVIENDO)
