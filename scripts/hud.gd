extends CanvasLayer

## HUD del nivel: puntaje, munición (cargador | reserva), zombies restantes,
## tiempo, objetivo, flecha hacia la salida, pausa y pantallas de victoria/derrota.
## process_mode = Always para que funcione con el juego pausado.

@onready var label_nivel: Label = $Superior/Izquierda/Nivel
@onready var label_tiempo: Label = $Superior/Izquierda/Tiempo
@onready var label_puntaje: Label = $Superior/Centro/Puntaje
@onready var label_record: Label = $Superior/Centro/Record
@onready var label_zombies: Label = $Superior/Derecha/Zombies
@onready var label_municion: Label = $Superior/Derecha/Municion
@onready var label_objetivo: Label = $Objetivo
@onready var label_aviso: Label = $Aviso
@onready var flecha: Sprite2D = $Flecha

@onready var panel_pausa: Control = $PanelPausa
@onready var panel_fin: Control = $PanelFin
@onready var titulo_fin: Label = $PanelFin/Caja/Titulo
@onready var detalle_fin: Label = $PanelFin/Caja/Detalle
@onready var boton_siguiente: Button = $PanelFin/Caja/Botones/Siguiente
@onready var boton_reintentar: Button = $PanelFin/Caja/Botones/Reintentar
@onready var flash_rojo: ColorRect = $FlashRojo
@onready var timer_volver_menu: Timer = $TimerVolverMenu
@onready var sonido_victoria: AudioStreamPlayer = $SonidoVictoria
@onready var sonido_derrota: AudioStreamPlayer = $SonidoDerrota

var juego_terminado: bool = false
var cargador_actual: int = 0
var reserva_actual: int = 0
var tween_aviso: Tween
var flechas_zombies: Array[Sprite2D] = []

const FLECHA_ROJA = preload("res://assets/ui/flecha_roja.png")


func _ready() -> void:
	panel_pausa.hide()
	panel_fin.hide()
	flecha.hide()
	label_aviso.modulate.a = 0.0
	flash_rojo.modulate.a = 0.0
	label_record.text = "RÉCORD  %d" % Global.puntaje_maximo


func configurar(numero: int, nombre: String) -> void:
	label_nivel.text = "NIVEL %d — %s" % [numero, nombre.to_upper()]


func actualizar_tiempo(tiempo: float) -> void:
	label_tiempo.text = Global.formatear_tiempo(tiempo)


func actualizar_puntaje(puntaje: int) -> void:
	label_puntaje.text = "%06d" % puntaje
	# pequeño "salto" del número al sumar puntos
	label_puntaje.pivot_offset = label_puntaje.size / 2.0
	label_puntaje.scale = Vector2(1.25, 1.25)
	create_tween().tween_property(label_puntaje, "scale", Vector2.ONE, 0.2)


func actualizar_zombies(vivos: int, total: int) -> void:
	label_zombies.text = "ZOMBIES  %d / %d" % [vivos, total]


func actualizar_municion(cargador: int, reserva: int) -> void:
	cargador_actual = cargador
	reserva_actual = reserva
	if cargador + reserva == 0:
		label_municion.text = "¡SIN BALAS!"
		label_municion.modulate = Color(1, 0.3, 0.3)
	else:
		label_municion.text = "BALAS  %d | %d" % [cargador, reserva]
		label_municion.modulate = Color(1, 0.55, 0.4) if cargador == 0 else Color.WHITE


func mostrar_recargando(esta_recargando: bool) -> void:
	if esta_recargando:
		label_municion.text = "RECARGANDO..."
		label_municion.modulate = Color(1, 0.85, 0.3)
	else:
		actualizar_municion(cargador_actual, reserva_actual)


func mostrar_objetivo(texto: String) -> void:
	label_objetivo.text = texto + "   ·   ESC pausa"


## Cartel grande en el medio que aparece y se desvanece
func mostrar_aviso(texto: String) -> void:
	label_aviso.text = texto
	if tween_aviso:
		tween_aviso.kill()
	label_aviso.modulate.a = 1.0
	label_aviso.pivot_offset = label_aviso.size / 2.0
	label_aviso.scale = Vector2(1.6, 1.6)
	tween_aviso = create_tween()
	tween_aviso.tween_property(label_aviso, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)
	tween_aviso.tween_interval(1.4)
	tween_aviso.tween_property(label_aviso, "modulate:a", 0.0, 0.5)


## Flecha alrededor del jugador que apunta a la salida
func apuntar_flecha(posicion_jugador_en_pantalla: Vector2, angulo: float) -> void:
	flecha.show()
	flecha.rotation = angulo
	flecha.position = posicion_jugador_en_pantalla + Vector2.RIGHT.rotated(angulo) * 64.0


func ocultar_flecha() -> void:
	flecha.hide()


## Flechas ROJAS hacia los últimos zombies (cuando quedan pocos), para que el
## jugador no se quede buscando al último tonto trabado en alguna habitación.
func apuntar_a_zombies(posicion_jugador_en_pantalla: Vector2, angulos: Array) -> void:
	while flechas_zombies.size() < angulos.size():
		var nueva = Sprite2D.new()
		nueva.texture = FLECHA_ROJA
		nueva.scale = Vector2(0.7, 0.7)
		add_child(nueva)
		flechas_zombies.append(nueva)
	for i in flechas_zombies.size():
		var f = flechas_zombies[i]
		f.visible = i < angulos.size()
		if f.visible:
			f.rotation = angulos[i]
			f.position = posicion_jugador_en_pantalla + Vector2.RIGHT.rotated(angulos[i]) * 52.0


#region Pausa

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pausa") and not juego_terminado:
		alternar_pausa()
		get_viewport().set_input_as_handled()
	elif juego_terminado and timer_volver_menu.time_left > 0.0 \
			and event is InputEventKey and event.pressed and event.physical_keycode == KEY_R:
		timer_volver_menu.stop()
		Global.reintentar_nivel()


func alternar_pausa() -> void:
	var pausado = not get_tree().paused
	get_tree().paused = pausado
	panel_pausa.visible = pausado
	if pausado:
		$PanelPausa/Caja/Continuar.grab_focus()


func _on_continuar_pressed() -> void:
	alternar_pausa()

#endregion


#region Fin de nivel

func mostrar_victoria(detalle: String, tiempo: float, puntaje: int, es_record_tiempo: bool,
		es_record_puntaje: bool, hay_siguiente: bool) -> void:
	juego_terminado = true
	titulo_fin.text = "NIVEL SUPERADO" if hay_siguiente else "¡JUEGO COMPLETADO!"
	titulo_fin.modulate = Color(0.35, 1.0, 0.95)
	var texto = detalle + "\nTiempo: " + Global.formatear_tiempo(tiempo)
	if es_record_tiempo:
		texto += "  ★ récord de tiempo"
	texto += "\nPUNTAJE: %d" % puntaje
	if es_record_puntaje:
		texto += "   ★ ¡NUEVO RÉCORD!"
	if hay_siguiente:
		texto += "\n(el puntaje pasa al siguiente nivel)"
	detalle_fin.text = texto
	boton_siguiente.visible = hay_siguiente
	boton_reintentar.visible = true
	panel_fin.show()
	_animar_titulo()
	sonido_victoria.play()
	if hay_siguiente:
		boton_siguiente.grab_focus()
	else:
		$PanelFin/Caja/Botones/Menu.grab_focus()


func mostrar_derrota(puntaje: int, es_record: bool) -> void:
	juego_terminado = true
	titulo_fin.text = "TE MORDIERON"
	titulo_fin.modulate = Color(1.0, 0.25, 0.4)
	var texto = "Puntaje: %d" % puntaje
	if es_record:
		texto += "   ★ ¡NUEVO RÉCORD!"
	detalle_fin.text = texto + "\nVolviendo al menú...\n(apretá R para reintentar ya)"
	boton_siguiente.visible = false
	boton_reintentar.visible = false
	panel_fin.show()
	_animar_titulo()
	sonido_derrota.play()
	var tween = create_tween()
	tween.tween_property(flash_rojo, "modulate:a", 0.55, 0.08)
	tween.tween_property(flash_rojo, "modulate:a", 0.25, 0.6)
	timer_volver_menu.start()


func _animar_titulo() -> void:
	titulo_fin.pivot_offset = titulo_fin.size / 2.0
	titulo_fin.scale = Vector2(2.5, 2.5)
	var tween = create_tween()
	tween.tween_property(titulo_fin, "scale", Vector2.ONE, 0.35)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_timer_volver_menu_timeout() -> void:
	Global.ir_al_menu()


func _on_siguiente_pressed() -> void:
	Global.ir_al_siguiente_nivel()


func _on_reintentar_pressed() -> void:
	Global.reintentar_nivel()


func _on_menu_pressed() -> void:
	Global.ir_al_menu()

#endregion
