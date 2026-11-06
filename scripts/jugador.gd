class_name Jugador extends CharacterBody2D

## JUGADOR - vista top-down estilo Hotline Miami.
## - Se mueve con WASD / flechas.
## - Mira SIEMPRE hacia el mouse usando get_global_mouse_position() + look_at().
## - Dispara con click izquierdo y recarga con R.
## - MUNICIÓN: arranca con 50 balas en total (12 en el cargador + 38 de reserva).
##   Recargar pasa balas de la reserva al cargador. Las cajas de munición del
##   piso suman balas a la reserva.
## La lógica de "qué puede hacer en cada momento" vive en los estados
## (scripts/estados/jugador). Acá están las acciones que esos estados usan.

signal municion_cambiada(cargador: int, reserva: int)
signal municion_recogida(cantidad: int)
signal recargando_cambio(esta_recargando: bool)
signal disparo_realizado
signal murio

@export_group("Movimiento")
@export var velocidad: float = 270.0
@export var aceleracion: float = 2400.0

@export_group("Arma")
@export var escena_bala: PackedScene
@export var cadencia: float = 0.15          ## segundos entre disparo y disparo
@export var municion_maxima: int = 12       ## balas que entran en el cargador
@export var balas_iniciales: int = 50       ## balas totales al empezar el nivel
@export var tiempo_recarga: float = 1.0
@export var dispersion_grados: float = 2.0  ## pequeña imprecisión del arma

const TEXTURA_ARMA = preload("res://assets/sprites/jugador/jugador_gun.png")
const TEXTURA_RECARGA = preload("res://assets/sprites/jugador/jugador_reload.png")

@onready var sprite: Sprite2D = $Sprite2D
@onready var punta_arma: Marker2D = $PuntaArma
@onready var anim_cuerpo: AnimationPlayer = $AnimCuerpo
@onready var anim_arma: AnimationPlayer = $AnimArma
@onready var maquina_estados: StateMachine = $StateMachine
@onready var sonido_disparo: AudioStreamPlayer2D = $Sonidos/Disparo
@onready var sonido_sin_balas: AudioStreamPlayer2D = $Sonidos/SinBalas
@onready var sonido_recarga: AudioStreamPlayer2D = $Sonidos/Recarga

var municion: int = 0      ## balas en el cargador
var reserva: int = 0       ## balas de repuesto (se usan al recargar)
var enfriamiento_disparo: float = 0.0
var esta_vivo: bool = true
var controles_activos: bool = true


func _ready() -> void:
	add_to_group("jugador")
	municion = min(municion_maxima, balas_iniciales)
	reserva = balas_iniciales - municion
	# avisamos al HUD cuando ya está todo cargado
	municion_cambiada.emit.call_deferred(municion, reserva)


func _process(delta: float) -> void:
	enfriamiento_disparo = max(enfriamiento_disparo - delta, 0.0)


#region Acciones que usan los estados

func leer_direccion() -> Vector2:
	if not controles_activos:
		return Vector2.ZERO
	return Input.get_vector("mover_izquierda", "mover_derecha", "mover_arriba", "mover_abajo")


func mover(delta: float, direccion: Vector2) -> void:
	# Aceleramos/frenamos suave hacia la velocidad deseada
	velocity = velocity.move_toward(direccion * velocidad, aceleracion * delta)
	move_and_slide()


## Gira al jugador para que mire a la posición del mouse
func apuntar() -> void:
	if not controles_activos:
		return
	var posicion_mouse: Vector2 = get_global_mouse_position()
	look_at(posicion_mouse)


func quiere_disparar() -> bool:
	return controles_activos and Input.is_action_pressed("disparar")


func quiere_recargar() -> bool:
	return controles_activos and Input.is_action_just_pressed("recargar") and puede_recargar()


func puede_recargar() -> bool:
	return municion < municion_maxima and reserva > 0


func balas_totales() -> int:
	return municion + reserva


func disparar() -> void:
	if enfriamiento_disparo > 0.0:
		return
	enfriamiento_disparo = cadencia

	if municion <= 0:
		sonido_sin_balas.play()
		return

	municion -= 1
	municion_cambiada.emit(municion, reserva)

	# Dirección: desde la punta del arma hacia el mouse (si el mouse no está
	# demasiado cerca), si no, hacia donde mira el jugador.
	var posicion_mouse = get_global_mouse_position()
	var direccion = Vector2.RIGHT.rotated(global_rotation)
	if global_position.distance_to(posicion_mouse) > punta_arma.position.length() + 16.0:
		direccion = punta_arma.global_position.direction_to(posicion_mouse)
	direccion = direccion.rotated(deg_to_rad(randf_range(-dispersion_grados, dispersion_grados)))

	var bala = escena_bala.instantiate()
	bala.global_position = punta_arma.global_position
	bala.direccion = direccion
	# El primer rayo de la bala sale desde el centro del jugador:
	# así no atraviesa una pared si el arma quedó "metida" en ella.
	bala.origen = global_position
	get_tree().current_scene.add_child(bala)

	anim_arma.stop()
	anim_arma.play("disparo")
	sonido_disparo.pitch_scale = randf_range(0.92, 1.08)
	sonido_disparo.play()
	disparo_realizado.emit()


func empezar_recarga() -> void:
	sprite.texture = TEXTURA_RECARGA
	sonido_recarga.play()
	recargando_cambio.emit(true)


func terminar_recarga() -> void:
	# pasamos de la reserva al cargador solo lo que falta
	var faltan = municion_maxima - municion
	var cargadas = min(faltan, reserva)
	municion += cargadas
	reserva -= cargadas
	sprite.texture = TEXTURA_ARMA
	recargando_cambio.emit(false)
	municion_cambiada.emit(municion, reserva)


## La llaman las cajas de munición del piso
func agregar_municion(cantidad: int) -> void:
	reserva += cantidad
	municion_cambiada.emit(municion, reserva)
	municion_recogida.emit(cantidad)


func cancelar_recarga() -> void:
	sprite.texture = TEXTURA_ARMA
	recargando_cambio.emit(false)

#endregion


## Se conecta con la señal "jugador_daniado" de cada Enemigo.
## Como en Hotline Miami, cualquier mordida mata: no importa si el ataque
## es 10 (tonto) o 120 (inteligente).
func recibir_danio(_cantidad: int) -> void:
	morir()


func morir() -> void:
	if not esta_vivo:
		return
	esta_vivo = false
	maquina_estados.change_to("Muerto")
	murio.emit()


## Se usa al ganar el nivel: el jugador queda quieto
func desactivar_controles() -> void:
	controles_activos = false
