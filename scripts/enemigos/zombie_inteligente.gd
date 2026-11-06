class_name ZombieInteligente
extends Enemigo
## ZOMBIE INTELIGENTE (rojizo).
##
## En vez de ir en línea recta "sin pensarlo", traza una RUTA para alcanzar al
## jugador evitando paredes y obstáculos (pathfinding). Para eso necesita:
##   - Un NavigationAgent2D como hijo.
##   - El NavigationRegion2D del nivel (se hornea solo al iniciar, ver nivel.gd).
##
## El código base es el de la documentación oficial de Godot
## ("Using NavigationAgents"), adaptado para que herede de Enemigo.

@onready var navigation_agent: NavigationAgent2D = $NavigationAgent2D
## Recalcula la ruta cada 0,25 s. Hacerlo en cada frame anda, pero es
## "un exagero": con un Timer alcanza y gasta mucho menos.
@onready var timer_ruta: Timer = $TimerRuta

# Anti-atascos: si casi no avanzó en un rato, recalcula la ruta ya mismo
var tiempo_sin_avanzar: float = 0.0
var ultima_posicion: Vector2


func _ready() -> void:
	super() # Ejecuta también el _ready() de Enemigo.
	ataque = 120 # El zombie inteligente pega mucho más fuerte.
	# vida = 3 y puntos = 250 se configuran en el Inspector (zombie_inteligente.tscn)

	navigation_agent.path_desired_distance = 6.0
	navigation_agent.target_desired_distance = 6.0

	# Igual que en la documentación: esperamos a que el mapa de navegación se
	# sincronice en el primer frame de física antes de pedir una ruta.
	actor_setup.call_deferred()


func actor_setup() -> void:
	await get_tree().physics_frame
	if jugador != null:
		set_movement_target(jugador.global_position)


func set_movement_target(movement_target: Vector2) -> void:
	navigation_agent.target_position = movement_target


func _on_timer_ruta_timeout() -> void:
	if jugador != null and esta_vivo:
		set_movement_target(jugador.global_position)


## Override del método mover() de Enemigo.
func mover(delta: float) -> void:
	# Si el mapa todavía no está listo, no hacemos nada.
	if NavigationServer2D.map_get_iteration_id(navigation_agent.get_navigation_map()) == 0:
		return

	var siguiente_punto: Vector2
	if navigation_agent.is_navigation_finished():
		# ya llegamos al final de la ruta: vamos directo al jugador
		siguiente_punto = jugador.global_position
	else:
		siguiente_punto = navigation_agent.get_next_path_position()

	caminar_hacia(global_position.direction_to(siguiente_punto), delta)
	revisar_atasco(delta)


func revisar_atasco(delta: float) -> void:
	var lejos_del_jugador = global_position.distance_to(jugador.global_position) > 48.0
	if lejos_del_jugador and global_position.distance_to(ultima_posicion) < velocidad * delta * 0.25:
		tiempo_sin_avanzar += delta
		if tiempo_sin_avanzar > 0.5:
			tiempo_sin_avanzar = 0.0
			set_movement_target(jugador.global_position)
	else:
		tiempo_sin_avanzar = 0.0
	ultima_posicion = global_position


## Override: además de lo común, deja de recalcular la ruta.
func al_morir() -> void:
	super()
	timer_ruta.stop()
