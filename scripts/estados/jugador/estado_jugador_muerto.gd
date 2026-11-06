extends EstadoJugador

## MUERTO: el jugador cae, deja de recibir input y queda en el piso.

func start() -> void:
	jugador.velocity = Vector2.ZERO
	jugador.anim_arma.stop()
	jugador.anim_cuerpo.play("muerte")
	jugador.get_node("Sonidos/Muerte").play()
	# sacamos sus colisiones para que los zombies no se traben con el cuerpo
	jugador.set_deferred("collision_layer", 0)


func on_physics_process(delta: float) -> void:
	# pequeño deslizamiento al caer
	jugador.velocity = jugador.velocity.move_toward(Vector2.ZERO, 900 * delta)
	jugador.move_and_slide()
