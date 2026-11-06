extends StateBase

## MUERTO: el cuerpo queda en el piso (como en Hotline Miami) sin colisiones.

var zombie: Enemigo:
	get:
		return controlled_node as Enemigo


func start() -> void:
	zombie.anim.play("muerte")
	zombie.sonido_muerte.play()
	zombie.al_morir()
	# deja de chocar y de morder
	zombie.set_deferred("collision_layer", 0)
	zombie.set_deferred("collision_mask", 1)
	zombie.area_ataque.set_deferred("monitoring", false)
	# lo mandamos al principio de su contenedor para que se dibuje DEBAJO
	# de los zombies vivos (pero encima del piso)
	zombie.get_parent().move_child.call_deferred(zombie, 0)


func on_physics_process(delta: float) -> void:
	# el cuerpo sale despedido un poquito por el disparo
	zombie.frenar(delta)
