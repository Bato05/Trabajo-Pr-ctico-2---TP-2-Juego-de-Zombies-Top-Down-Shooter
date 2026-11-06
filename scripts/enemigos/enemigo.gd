class_name Enemigo
extends CharacterBody2D
## Clase BASE de todos los enemigos (HERENCIA, como en la clase del 23/10).
##
## Igual que en POO (Animal -> Gato / Perro), acá va todo lo que es COMÚN a los
## dos zombies para no repetir código: vida, velocidad, ataque, recibir disparos,
## morir, dejar sangre, el portazo, sonidos y animaciones.
## Gracias al "class_name Enemigo", los scripts de los zombies hacen
## "extends Enemigo" y heredan todo esto automáticamente.
##
## Lo ÚNICO que cambia entre un zombie y otro es CÓMO SE MUEVE:
##   - ZombieTonto:       va en línea recta hacia el jugador (se traba en paredes)
##   - ZombieInteligente: traza una ruta con NavigationAgent2D (esquiva todo)
## Por eso existe el método mover(), que cada hijo SOBRESCRIBE (override).
##
## La escena enemigo.tscn NO se pone en los niveles: solo sirve para que
## zombie_tonto.tscn y zombie_inteligente.tscn hereden de ella.

## Avisa al jugador que recibió daño (se conecta en _ready con jugador.recibir_danio)
signal jugador_daniado(cantidad: int)
## Avisa al nivel que este enemigo murió (para contar los que quedan)
signal murio(enemigo: Enemigo)

# Con @export las propiedades aparecen en el Inspector para modificarlas a mano.
@export var velocidad: float = 110.0
@export var vida: int = 1
## El ataque se declara SIN valor: cada hijo le asigna el suyo en su _ready()
## (ZombieTonto = 10, ZombieInteligente = 120). En Hotline Miami cualquier
## mordida mata, así que el jugador muere igual; el valor queda para mostrar
## la herencia y por si más adelante querés un sistema de energía.
@export var ataque: int
@export var velocidad_giro: float = 7.0
@export var fuerza_empuje_bala: float = 420.0  ## retroceso al recibir un disparo
## segundos que tarda en "despertar" al empezar el nivel
@export var retraso_inicio: float = 1.2
## color para diferenciar los tipos de zombie
@export var tinte: Color = Color.WHITE
## puntos que da al morir (se suman al puntaje de la partida)
@export var puntos: int = 100
## probabilidad (0 a 1) de soltar una caja chica de munición al morir
@export_range(0.0, 1.0) var probabilidad_municion: float = 0.25
@export var balas_que_suelta: int = 6

@export_group("Separación entre zombies")
## Los zombies NO chocan físicamente entre sí (collision_mask sin la capa 3),
## así nunca se traban en una puerta. Para que no se encimen en un solo
## sprite, cada uno se aleja SUAVEMENTE de los vecinos que tiene muy cerca.
@export var radio_separacion: float = 36.0
@export var fuerza_separacion: float = 0.7

const ESCENA_SANGRE = preload("res://scenes/entidades/mancha_sangre.tscn")
const ESCENA_MUNICION = preload("res://scenes/entidades/municion.tscn")

# Referencia al jugador (lo buscamos por el grupo "jugador", como en el ejemplo)
@onready var jugador: Jugador = get_tree().get_first_node_in_group("jugador")

@onready var sprite: Sprite2D = $Visual/Sprite2D
@onready var anim: AnimationPlayer = $AnimationPlayer
@onready var maquina_estados: StateMachine = $StateMachine
@onready var area_ataque: Area2D = $AreaAtaque
@onready var timer_grunido: Timer = $TimerGrunido
@onready var sonido_impacto: AudioStreamPlayer2D = $Sonidos/Impacto
@onready var sonido_muerte: AudioStreamPlayer2D = $Sonidos/Muerte
@onready var sonido_grunido: AudioStreamPlayer2D = $Sonidos/Grunido

var empuje: Vector2 = Vector2.ZERO
var esta_vivo: bool = true
var tiempo_aturdido: float = 0.0


func _ready() -> void:
	add_to_group("enemigos")
	sprite.self_modulate = tinte
	# un poco de variación para que no caminen todos "sincronizados"
	velocidad *= randf_range(0.92, 1.08)
	anim.speed_scale = randf_range(0.9, 1.1)
	timer_grunido.start(randf_range(2.0, 7.0))

	if jugador != null and jugador.has_method("recibir_danio"):
		jugador_daniado.connect(jugador.recibir_danio)


#region Movimiento

## Lo llama el estado "Perseguir" en cada frame de física.
## Primero espera a "despertar"; después delega en mover(), que es
## distinto en cada hijo.
func perseguir(delta: float) -> void:
	if jugador == null or not is_instance_valid(jugador):
		return
	if retraso_inicio > 0.0:
		retraso_inicio -= delta
		girar_hacia(global_position.direction_to(jugador.global_position).angle(), delta)
		return
	mover(delta)


## Método que los hijos SOBRESCRIBEN (override). Cada zombie se mueve distinto.
func mover(_delta: float) -> void:
	pass


## Movimiento común: aplica la dirección elegida por el hijo + el empuje de
## los disparos, gira el cuerpo y llama a move_and_slide().
func caminar_hacia(direccion: Vector2, delta: float) -> void:
	var separacion: Vector2 = calcular_separacion() * fuerza_separacion
	velocity = (direccion + separacion) * velocidad + empuje
	empuje = empuje.move_toward(Vector2.ZERO, 1200.0 * delta)
	if direccion != Vector2.ZERO:
		girar_hacia(direccion.angle(), delta)
	move_and_slide()


## Suma un pequeño "empujón" alejándose de cada zombie vivo que esté más cerca
## que radio_separacion. Cuanto más cerca, más fuerte. Es una fuerza SUAVE
## (no una colisión), por eso dos zombies pueden pasar juntos por una puerta.
func calcular_separacion() -> Vector2:
	var resultado := Vector2.ZERO
	for otro in get_tree().get_nodes_in_group("enemigos"):
		if otro == self or not otro.esta_vivo:
			continue
		var diferencia: Vector2 = global_position - otro.global_position
		var distancia: float = diferencia.length()
		if distancia < radio_separacion:
			if distancia < 0.01:
				# justo encima: elegimos una dirección al azar para desempatar
				diferencia = Vector2.RIGHT.rotated(randf() * TAU)
				distancia = 0.01
			resultado += diferencia / distancia * (1.0 - distancia / radio_separacion)
	return resultado


func girar_hacia(angulo: float, delta: float) -> void:
	rotation = lerp_angle(rotation, angulo, 1.0 - exp(-velocidad_giro * delta))


## Se usa estando aturdido o muerto: solo se desliza por el empuje
func frenar(delta: float) -> void:
	velocity = empuje
	empuje = empuje.move_toward(Vector2.ZERO, 900.0 * delta)
	move_and_slide()

#endregion


#region Ataque

## Función común a todos los enemigos. No está definida en ZombieTonto ni en
## ZombieInteligente, pero como la heredan de Enemigo la pueden llamar igual.
## (Se escribe "daniar" porque en el código no usamos la ñ.)
func daniar() -> void:
	jugador_daniado.emit(ataque)


## Señal body_entered del AreaAtaque (la misma para los dos zombies).
func _on_area_ataque_body_entered(body: Node2D) -> void:
	# Solo muerde si está persiguiendo (aturdido o muerto no hace daño)
	if esta_vivo and maquina_estados.current_state_name() == "Perseguir" and body.is_in_group("jugador"):
		daniar()


## Por si al salir del aturdimiento ya estaba encima del jugador
func atacar_si_toca_jugador() -> void:
	for cuerpo in area_ataque.get_overlapping_bodies():
		if cuerpo.is_in_group("jugador"):
			daniar()

#endregion


#region Daño

## Lo llama la bala cuando le pega a un enemigo.
func recibir_disparo(cantidad: int, direccion: Vector2) -> void:
	if not esta_vivo:
		return
	vida -= cantidad
	empuje = direccion * fuerza_empuje_bala
	sonido_impacto.pitch_scale = randf_range(0.9, 1.15)
	sonido_impacto.play()
	_salpicar(direccion, 10)

	if vida <= 0:
		morir(direccion)
	else:
		# flash al recibir el golpe
		sprite.self_modulate = Color(3, 1.5, 1.5)
		var tween := create_tween()
		tween.tween_property(sprite, "self_modulate", tinte, 0.15)


func morir(direccion: Vector2 = Vector2.ZERO) -> void:
	if not esta_vivo:
		return
	esta_vivo = false
	empuje = direccion * fuerza_empuje_bala * 1.4
	_dejar_mancha()
	_salpicar(direccion, 24)
	if randf() < probabilidad_municion:
		_soltar_municion.call_deferred()
	maquina_estados.change_to("Muerto")
	murio.emit(self)


## Golpe de puerta (mecánica clásica de Hotline Miami)
func aturdir(segundos: float, direccion: Vector2) -> void:
	if not esta_vivo:
		return
	tiempo_aturdido = segundos
	empuje = direccion * 380.0
	maquina_estados.change_to("Aturdido")


## Los hijos lo sobrescriben si tienen algo extra que apagar al morir
func al_morir() -> void:
	timer_grunido.stop()
	sonido_grunido.stop()


func _soltar_municion() -> void:
	var caja = ESCENA_MUNICION.instantiate()
	caja.cantidad = balas_que_suelta
	caja.global_position = global_position
	var contenedor = get_tree().get_first_node_in_group("municiones")
	if contenedor == null:
		contenedor = get_tree().current_scene
	contenedor.add_child(caja)


func _dejar_mancha() -> void:
	var mancha = ESCENA_SANGRE.instantiate()
	mancha.global_position = global_position
	var contenedor = get_tree().get_first_node_in_group("manchas")
	if contenedor == null:
		contenedor = get_tree().current_scene
	contenedor.add_child(mancha)


func _salpicar(direccion: Vector2, cantidad: int) -> void:
	# Partículas de sangre creadas por código (se borran solas)
	var particulas = CPUParticles2D.new()
	particulas.one_shot = true
	particulas.emitting = false
	particulas.amount = cantidad
	particulas.lifetime = 0.45
	particulas.explosiveness = 0.95
	particulas.direction = direccion if direccion != Vector2.ZERO else Vector2.RIGHT
	particulas.spread = 35.0
	particulas.initial_velocity_min = 120.0
	particulas.initial_velocity_max = 320.0
	particulas.damping_min = 400.0
	particulas.damping_max = 600.0
	particulas.scale_amount_min = 3.0
	particulas.scale_amount_max = 6.0
	particulas.color = Color(0.6, 0.0, 0.05)
	particulas.global_position = global_position
	get_tree().current_scene.add_child(particulas)
	particulas.emitting = true
	particulas.finished.connect(particulas.queue_free)

#endregion


func _on_timer_grunido_timeout() -> void:
	if esta_vivo:
		sonido_grunido.pitch_scale = randf_range(0.8, 1.2)
		sonido_grunido.play()
		timer_grunido.start(randf_range(4.0, 10.0))
