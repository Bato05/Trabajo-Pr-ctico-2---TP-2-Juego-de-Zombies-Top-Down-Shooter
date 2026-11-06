extends EstadoJugador

## RECARGANDO: se puede mover y apuntar, pero NO disparar.
## Cuando termina el tiempo de recarga vuelve a Idle o Moviendo.

var tiempo_restante: float = 0.0


func start() -> void:
	tiempo_restante = jugador.tiempo_recarga
	jugador.empezar_recarga()
	jugador.anim_cuerpo.play("recargar")


func on_physics_process(delta: float) -> void:
	jugador.apuntar()
	var direccion = jugador.leer_direccion()
	jugador.mover(delta, direccion)

	tiempo_restante -= delta
	if tiempo_restante <= 0.0:
		jugador.terminar_recarga()
		if direccion == Vector2.ZERO:
			state_machine.change_to(NombresEstadosJugador.IDLE)
		else:
			state_machine.change_to(NombresEstadosJugador.MOVIENDO)


func end() -> void:
	# Si salimos antes de tiempo (por ejemplo, porque nos mordieron)
	if tiempo_restante > 0.0:
		jugador.cancelar_recarga()
