class_name ZombieTonto
extends Enemigo
## ZOMBIE TONTO (el verde de siempre).
##
## Calcula la dirección desde donde está él hacia donde está el jugador y camina
## en esa dirección, sin importarle si hay una pared en el medio: si choca con
## la pared se queda trabado ahí (por eso es "tonto").
##
## Fijate que acá NO están declaradas "velocidad", "vida", "ataque" ni "jugador":
## todo eso viene heredado de Enemigo.


func _ready() -> void:
	super() # Ejecuta también el _ready() de Enemigo (la clase padre).
	ataque = 10 # El zombie tonto no hace tanto daño.
	# vida = 2 y puntos = 100 se configuran en el Inspector (zombie_tonto.tscn)


## Override del método mover() de Enemigo.
func mover(delta: float) -> void:
	# Vector de dirección: desde la posición del zombie HACIA la del jugador.
	var direccion: Vector2 = global_position.direction_to(jugador.global_position)
	# caminar_hacia() (heredado) multiplica por la velocidad y hace move_and_slide().
	# Si hay una pared en el medio, no pasa.
	caminar_hacia(direccion, delta)
