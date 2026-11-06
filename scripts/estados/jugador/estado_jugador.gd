class_name EstadoJugador extends StateBase

## Base para los estados del jugador: nos da "jugador" ya tipado
## y una función común para disparar / recargar.

var jugador: Jugador:
	get:
		return controlled_node as Jugador


## Revisa disparo y recarga. Devuelve true si cambió de estado.
func procesar_arma() -> bool:
	if jugador.quiere_recargar():
		state_machine.change_to(NombresEstadosJugador.RECARGANDO)
		return true
	if jugador.quiere_disparar():
		# cargador vacío + gatillo = recarga automática (si queda reserva)
		if jugador.municion <= 0 and jugador.enfriamiento_disparo <= 0.0:
			jugador.disparar()  # suena el "click" vacío
			if jugador.puede_recargar():
				state_machine.change_to(NombresEstadosJugador.RECARGANDO)
				return true
			return false
		jugador.disparar()
	return false
