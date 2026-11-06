extends Control

## MENÚ PRINCIPAL
## - Nivel 1 (arranca con puntaje 0) / Nivel 2 (arranca con el puntaje que
##   traías al terminar el nivel 1, guardado en archivo)
## - Muestra el RÉCORD de puntaje (persistente)
## - Opciones: volumen general, música y efectos (se guardan en disco)
## - Salir

@onready var panel_principal: Control = $Centro/Principal
@onready var panel_opciones: Control = $Centro/Opciones
@onready var slider_general: HSlider = $Centro/Opciones/General/Slider
@onready var slider_musica: HSlider = $Centro/Opciones/Musica/Slider
@onready var slider_efectos: HSlider = $Centro/Opciones/Efectos/Slider
@onready var valor_general: Label = $Centro/Opciones/General/Valor
@onready var valor_musica: Label = $Centro/Opciones/Musica/Valor
@onready var valor_efectos: Label = $Centro/Opciones/Efectos/Valor
@onready var label_records: Label = $Centro/Principal/Records
@onready var sonido_prueba: AudioStreamPlayer = $SonidoPrueba
@onready var musica: AudioStreamPlayer = $Musica

var cargando_valores: bool = false


func _ready() -> void:
	get_tree().paused = false
	Input.set_custom_mouse_cursor(null)
	musica.finished.connect(musica.play)

	# Ponemos los sliders con los valores guardados
	cargando_valores = true
	slider_general.value = Global.volumen_general * 100.0
	slider_musica.value = Global.volumen_musica * 100.0
	slider_efectos.value = Global.volumen_efectos * 100.0
	cargando_valores = false
	_actualizar_textos_volumen()
	_actualizar_records()

	panel_opciones.hide()
	panel_principal.show()
	$Centro/Principal/Botones/Nivel1.grab_focus()


func _actualizar_records() -> void:
	var texto = "RÉCORD DE PUNTAJE: %d" % Global.puntaje_maximo
	for numero in Global.NIVELES.keys():
		var record = "--:--.--"
		if Global.mejores_tiempos.has(numero):
			record = Global.formatear_tiempo(Global.mejores_tiempos[numero])
		texto += "     Nivel %d: %s" % [numero, record]
	label_records.text = texto
	# el botón del nivel 2 muestra con cuántos puntos arrancás
	if Global.puntaje_al_llegar.has(2):
		$Centro/Principal/Botones/Nivel2.text = "NIVEL 2 — EL LABORATORIO  (%d pts)" % Global.puntaje_al_llegar[2]


func _actualizar_textos_volumen() -> void:
	valor_general.text = "%d%%" % slider_general.value
	valor_musica.text = "%d%%" % slider_musica.value
	valor_efectos.text = "%d%%" % slider_efectos.value


#region Botones principales

func _on_button_nivel_1_pressed() -> void:
	Global.empezar_desde_menu(1)


func _on_button_nivel_2_pressed() -> void:
	Global.empezar_desde_menu(2)


func _on_button_opciones_pressed() -> void:
	panel_principal.hide()
	panel_opciones.show()
	slider_general.grab_focus()


func _on_salir_pressed() -> void:
	get_tree().quit()

#endregion


#region Opciones de volumen

func _on_slider_general_value_changed(valor: float) -> void:
	Global.volumen_general = valor / 100.0
	_al_cambiar_volumen()


func _on_slider_musica_value_changed(valor: float) -> void:
	Global.volumen_musica = valor / 100.0
	_al_cambiar_volumen()


func _on_slider_efectos_value_changed(valor: float) -> void:
	Global.volumen_efectos = valor / 100.0
	_al_cambiar_volumen()
	if not cargando_valores:
		sonido_prueba.play()  # para escuchar cómo suenan los efectos


func _al_cambiar_volumen() -> void:
	if cargando_valores:
		return
	Global.aplicar_volumenes()
	_actualizar_textos_volumen()


func _on_volver_pressed() -> void:
	Global.grabar()
	panel_opciones.hide()
	panel_principal.show()
	$Centro/Principal/Botones/Opciones.grab_focus()

#endregion
