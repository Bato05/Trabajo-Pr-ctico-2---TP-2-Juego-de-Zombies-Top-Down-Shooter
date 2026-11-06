extends StateBase

## ATURDIDO: le pegaron con una puerta. No se mueve ni muerde por un rato.

var zombie: Enemigo:
	get:
		return controlled_node as Enemigo


func start() -> void:
	zombie.anim.play("aturdido")
	zombie.get_node("Sonidos/GolpePuerta").play()


func on_physics_process(delta: float) -> void:
	zombie.frenar(delta)
	zombie.tiempo_aturdido -= delta
	if zombie.tiempo_aturdido <= 0.0:
		state_machine.change_to("Perseguir")
