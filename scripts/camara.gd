extends Camera2D

## Cámara estilo Hotline Miami: sigue al jugador y se adelanta un poco
## hacia donde apunta el mouse. Además tiembla con cada disparo.

@export var objetivo: Node2D
@export var adelanto_mouse: float = 0.3   ## cuánto se corre hacia el mouse (0 = nada)
@export var suavizado: float = 8.0

var temblor: float = 0.0


func _ready() -> void:
	make_current()
	if objetivo:
		global_position = objetivo.global_position


func _process(delta: float) -> void:
	if objetivo == null or not is_instance_valid(objetivo):
		return

	# Posición del mouse respecto al centro de la pantalla
	var tamanio_pantalla = get_viewport_rect().size
	var mouse_desde_centro = get_viewport().get_mouse_position() - tamanio_pantalla / 2.0
	var destino = objetivo.global_position + mouse_desde_centro * adelanto_mouse / zoom

	global_position = global_position.lerp(destino, 1.0 - exp(-suavizado * delta))

	if temblor > 0.0:
		offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * temblor
		temblor = move_toward(temblor, 0.0, 30.0 * delta)
	else:
		offset = Vector2.ZERO


func sacudir(fuerza: float) -> void:
	temblor = max(temblor, fuerza)
