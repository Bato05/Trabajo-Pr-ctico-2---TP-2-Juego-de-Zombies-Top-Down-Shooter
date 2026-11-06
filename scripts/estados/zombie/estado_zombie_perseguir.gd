extends StateBase

## PERSEGUIR: el zombie va siempre hacia el jugador.
## Llama a perseguir() del Enemigo, que a su vez usa mover():
## cada tipo de zombie (tonto / inteligente) se mueve a su manera.

var zombie: Enemigo:
	get:
		return controlled_node as Enemigo


func start() -> void:
	zombie.anim.play("caminar")
	# por si al salir del aturdimiento ya estaba encima del jugador
	zombie.atacar_si_toca_jugador()


func on_physics_process(delta: float) -> void:
	zombie.perseguir(delta)
