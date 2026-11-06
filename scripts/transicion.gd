extends CanvasLayer

## AUTOLOAD "Transicion" - FUNDIDO A NEGRO entre el menú y los niveles.
##
## Es lo que mostró el profe: un CanvasLayer con un rectángulo negro que se
## pone DELANTE de todo el juego (layer = 100).
##   - fundido a negro: subimos la opacidad del rectángulo (0 -> 1)
##   - cambiamos de escena mientras la pantalla está negra
##   - aparecer: bajamos la opacidad (1 -> 0) y se empieza a ver el juego
## Las dos animaciones están en el AnimationPlayer ("fundido_negro" y "aparecer").

@onready var negro: ColorRect = $Negro
@onready var anim: AnimationPlayer = $AnimationPlayer

var en_transicion: bool = false


func _ready() -> void:
	# Funciona aunque el juego esté pausado (por ejemplo desde el menú de pausa)
	process_mode = Node.PROCESS_MODE_ALWAYS
	# Al abrir el juego arranca en negro y aparece el menú
	negro.modulate.a = 1.0
	anim.play("aparecer")


## Cambia de escena con fundido: negro -> cambio -> aparecer
func cambiar_escena(ruta: String) -> void:
	if en_transicion:
		return
	en_transicion = true
	# mientras está en negro bloqueamos los clicks
	negro.mouse_filter = Control.MOUSE_FILTER_STOP

	anim.play("fundido_negro")
	await anim.animation_finished

	get_tree().paused = false
	get_tree().change_scene_to_file(ruta)
	# esperamos a que la escena nueva esté cargada
	await get_tree().process_frame
	await get_tree().process_frame

	anim.play("aparecer")
	await anim.animation_finished
	negro.mouse_filter = Control.MOUSE_FILTER_IGNORE
	en_transicion = false
