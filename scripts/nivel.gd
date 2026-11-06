extends Node2D

## NIVEL - script compartido por nivel_1 y nivel_2.
## Se encarga de:
##  - hornear la navegación a partir del TileMapLayer de paredes + obstáculos
##  - contar zombies y sumar PUNTAJE por cada uno (Global.puntaje)
##  - la PUERTA DE SALIDA: se abre cuando no queda ningún zombie, y salir
##    por ella es la forma de pasar el nivel
##  - la derrota: si un zombie toca al jugador -> se vuelve al menú

@export var numero_nivel: int = 1
@export var nombre_nivel: String = "La Casa"
## Bonus por tiempo: se gana (segundos_objetivo - tiempo) * 10 puntos
@export var segundos_objetivo: float = 120.0

const MIRA = preload("res://assets/ui/mira.png")
const PUNTOS_POR_NIVEL := 1000
const PUNTOS_POR_BALA_SOBRANTE := 5
## Cuando quedan estos zombies o menos, aparecen flechas rojas hacia ellos
const MOSTRAR_ZOMBIES_RESTANTES := 3

@onready var region_navegacion: NavigationRegion2D = $NavigationRegion2D
@onready var piso: TileMapLayer = $NavigationRegion2D/Piso
@onready var contenedor_zombies: Node2D = $Zombies
@onready var jugador: Jugador = $Jugador
@onready var puerta_salida = $PuertaSalida
@onready var camara: Camera2D = $Camara
@onready var hud = $HUD
@onready var musica: AudioStreamPlayer = $Musica

var total_zombies: int = 0
var zombies_vivos: int = 0
var tiempo: float = 0.0
var terminado: bool = false


func _ready() -> void:
	Global.nivel_actual = numero_nivel
	Input.set_custom_mouse_cursor(MIRA, Input.CURSOR_ARROW, Vector2(16, 16))

	hornear_navegacion()

	# Contamos los zombies y escuchamos cuando muere cada uno
	for zombie in contenedor_zombies.get_children():
		if zombie is Enemigo:
			total_zombies += 1
			zombie.murio.connect(_on_zombie_murio)
	zombies_vivos = total_zombies

	jugador.municion_cambiada.connect(hud.actualizar_municion)
	jugador.recargando_cambio.connect(hud.mostrar_recargando)
	jugador.municion_recogida.connect(_on_municion_recogida)
	jugador.disparo_realizado.connect(_on_jugador_disparo)
	jugador.murio.connect(_on_jugador_murio)
	puerta_salida.jugador_salio.connect(_on_jugador_salio)
	puerta_salida.jugador_cerca_cerrada.connect(_on_puerta_cerrada_tocada)

	hud.configurar(numero_nivel, nombre_nivel)
	hud.actualizar_zombies(zombies_vivos, total_zombies)
	hud.actualizar_puntaje(Global.puntaje)
	hud.mostrar_objetivo("Eliminá a TODOS los zombies para abrir la SALIDA")

	musica.finished.connect(musica.play)  # loop de la música


func _process(delta: float) -> void:
	if not terminado:
		tiempo += delta
		hud.actualizar_tiempo(tiempo)
	if not jugador.esta_vivo or terminado:
		hud.apuntar_a_zombies(Vector2.ZERO, [])
		return
	var en_pantalla: Vector2 = jugador.get_global_transform_with_canvas().origin
	# flecha verde que apunta a la salida una vez abierta
	if puerta_salida.abierta:
		var angulo = (puerta_salida.global_position - jugador.global_position).angle()
		hud.apuntar_flecha(en_pantalla, angulo)
	# flechas rojas hacia los últimos zombies
	var angulos = []
	if zombies_vivos <= MOSTRAR_ZOMBIES_RESTANTES:
		for zombie in contenedor_zombies.get_children():
			if zombie is Enemigo and zombie.esta_vivo:
				angulos.append((zombie.global_position - jugador.global_position).angle())
	hud.apuntar_a_zombies(en_pantalla, angulos)


## Arma el polígono de navegación en tiempo de ejecución:
## contorno = todo el piso; obstáculos = colisiones de paredes y objetos (capa 1).
## Así podés editar el mapa con el TileMap y la IA se adapta sola.
func hornear_navegacion() -> void:
	var poligono: NavigationPolygon = region_navegacion.navigation_polygon
	var celdas: Rect2i = piso.get_used_rect()
	var tamanio_tile: Vector2 = Vector2(piso.tile_set.tile_size)
	var inicio: Vector2 = piso.position + Vector2(celdas.position) * tamanio_tile
	var fin: Vector2 = piso.position + Vector2(celdas.end) * tamanio_tile

	poligono.clear_outlines()
	poligono.add_outline(PackedVector2Array([
		inicio, Vector2(fin.x, inicio.y), fin, Vector2(inicio.x, fin.y)
	]))
	region_navegacion.bake_navigation_polygon(false)

	# De paso limitamos la cámara a los bordes del mapa (con un margen)
	var margen = 96
	camara.limit_left = int(inicio.x) - margen
	camara.limit_top = int(inicio.y) - margen
	camara.limit_right = int(fin.x) + margen
	camara.limit_bottom = int(fin.y) + margen


#region Puntaje

func _on_zombie_murio(zombie: Enemigo) -> void:
	zombies_vivos -= 1
	Global.sumar_puntos(zombie.puntos)
	hud.actualizar_puntaje(Global.puntaje)
	hud.actualizar_zombies(zombies_vivos, total_zombies)
	mostrar_texto_flotante(zombie.global_position, "+%d" % zombie.puntos, Color(1, 0.9, 0.3))
	camara.sacudir(7.0)
	if zombies_vivos <= 0:
		abrir_salida()
	elif zombies_vivos == MOSTRAR_ZOMBIES_RESTANTES:
		hud.mostrar_aviso("¡QUEDAN %d! SEGUÍ LAS FLECHAS ROJAS" % zombies_vivos)


func _on_municion_recogida(cantidad: int) -> void:
	mostrar_texto_flotante(jugador.global_position, "+%d BALAS" % cantidad, Color(0.6, 1, 0.6))


## Texto que sube y se desvanece en el mundo (ej: "+250")
func mostrar_texto_flotante(posicion: Vector2, texto: String, color: Color) -> void:
	var etiqueta = Label.new()
	etiqueta.text = texto
	var ajustes = LabelSettings.new()
	ajustes.font_size = 22
	ajustes.font_color = color
	ajustes.outline_size = 6
	ajustes.outline_color = Color.BLACK
	etiqueta.label_settings = ajustes
	etiqueta.z_index = 20
	etiqueta.position = posicion + Vector2(-30, -40)
	add_child(etiqueta)
	var tween = etiqueta.create_tween().set_parallel(true)
	tween.tween_property(etiqueta, "position:y", etiqueta.position.y - 45, 0.9)
	tween.tween_property(etiqueta, "modulate:a", 0.0, 0.9).set_delay(0.3)
	tween.chain().tween_callback(etiqueta.queue_free)

#endregion


#region Salida y fin del nivel

func abrir_salida() -> void:
	puerta_salida.desbloquear()
	hud.mostrar_aviso("¡SALIDA ABIERTA!")
	hud.mostrar_objetivo("¡Salida abierta! Seguí la flecha verde y salí por la puerta")


func _on_puerta_cerrada_tocada() -> void:
	hud.mostrar_aviso("FALTAN %d ZOMBIES" % zombies_vivos)


func _on_jugador_disparo() -> void:
	camara.sacudir(4.0)


func _on_jugador_salio() -> void:
	if terminado:
		return
	terminado = true
	jugador.desactivar_controles()
	hud.ocultar_flecha()

	# Bonus del nivel
	var bonus_tiempo = max(0, int((segundos_objetivo - tiempo) * 10.0))
	var bonus_balas = jugador.balas_totales() * PUNTOS_POR_BALA_SOBRANTE
	Global.sumar_puntos(PUNTOS_POR_NIVEL + bonus_tiempo + bonus_balas)
	hud.actualizar_puntaje(Global.puntaje)

	var record_anterior = Global.puntaje_maximo
	var es_record_tiempo = Global.completar_nivel(numero_nivel, tiempo)
	var es_record_puntaje = Global.puntaje > record_anterior
	var detalle = "Nivel superado: +%d\nBonus tiempo: +%d   ·   Balas sobrantes: +%d" % [PUNTOS_POR_NIVEL, bonus_tiempo, bonus_balas]
	hud.mostrar_victoria(detalle, tiempo, Global.puntaje, es_record_tiempo, es_record_puntaje, Global.hay_siguiente_nivel())
	get_tree().paused = true  # el HUD sigue funcionando (process_mode = Always)


func _on_jugador_murio() -> void:
	if terminado:
		return
	terminado = true
	camara.sacudir(14.0)
	hud.ocultar_flecha()
	var es_record = Global.actualizar_puntaje_maximo()
	hud.mostrar_derrota(Global.puntaje, es_record)  # el HUD vuelve al menú después de unos segundos

#endregion
