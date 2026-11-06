extends Node2D

## PUERTA DE SALIDA del nivel (consigna del profe):
## "Cada nivel tiene una puerta para pasar el nivel, y para poder abrirla y
##  salir hay que haber matado a los zombies del nivel".
##
## - Arranca CERRADA (roja): un StaticBody2D tapa el hueco.
## - Cuando el nivel avisa que no quedan zombies -> desbloquear():
##   se pone verde, las hojas se abren y se libera el paso.
## - Si el jugador cruza la puerta abierta -> señal jugador_salio (gana el nivel).
## El +Y local apunta hacia AFUERA del mapa.

signal jugador_salio
signal jugador_cerca_cerrada

const COLOR_CERRADA := Color(1.0, 0.2, 0.3)
const COLOR_ABIERTA := Color(0.3, 1.0, 0.5)

@onready var hoja_izquierda: Sprite2D = $HojaIzquierda
@onready var hoja_derecha: Sprite2D = $HojaDerecha
@onready var bloqueo_forma: CollisionShape2D = $Bloqueo/CollisionShape2D
@onready var luz: Polygon2D = $Luz
@onready var cartel: Label = $Cartel
@onready var particulas: CPUParticles2D = $Particulas
@onready var sonido: AudioStreamPlayer2D = $Sonido

var abierta: bool = false


func _ready() -> void:
	_pintar(COLOR_CERRADA)
	cartel.text = "SALIDA CERRADA"


func desbloquear() -> void:
	if abierta:
		return
	abierta = true
	_pintar(COLOR_ABIERTA)
	cartel.text = "SALIDA"
	bloqueo_forma.set_deferred("disabled", true)
	particulas.emitting = true
	sonido.play()
	var tween = create_tween().set_parallel(true)
	tween.tween_property(hoja_izquierda, "position:x", -46.0, 0.5).set_trans(Tween.TRANS_BACK)
	tween.tween_property(hoja_derecha, "position:x", 46.0, 0.5).set_trans(Tween.TRANS_BACK)


func _pintar(color: Color) -> void:
	luz.color = color
	cartel.modulate = color


## Area2D "ZonaSalida": está del lado de afuera del bloqueo, así que solo
## se puede tocar cuando la puerta está abierta.
func _on_zona_salida_body_entered(body: Node2D) -> void:
	if abierta and body is Jugador and body.esta_vivo:
		jugador_salio.emit()


## Area2D "ZonaAviso": si el jugador se acerca con la puerta cerrada, el HUD le
## recuerda que tiene que matar a todos los zombies.
func _on_zona_aviso_body_entered(body: Node2D) -> void:
	if not abierta and body is Jugador:
		jugador_cerca_cerrada.emit()
