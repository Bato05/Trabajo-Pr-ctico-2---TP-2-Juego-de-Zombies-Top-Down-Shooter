extends EstadoJugador

## MOVIENDO: camina mientras apunta y dispara (como en Hotline Miami).

func start() -> void:
	jugador.anim_cuerpo.play("caminar")


func on_physics_process(delta: float) -> void:
	jugador.apuntar()
	var direccion = jugador.leer_direccion()
	jugador.mover(delta, direccion)

	if procesar_arma():
		return
	if direccion == Vector2.ZERO:
		state_machine.change_to(NombresEstadosJugador.IDLE)
