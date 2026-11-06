extends Node

## AUTOLOAD "Global"
## Guarda todo lo que tiene que sobrevivir entre escenas:
##   - volúmenes
##   - el PUNTAJE de la partida (pasa del nivel 1 al nivel 2)
##   - el récord de puntaje y los mejores tiempos
## y lo PERSISTE en un archivo (user://) para que no se pierda al cerrar el juego.

const ESCENA_MENU := "res://scenes/menu.tscn"
const NIVELES := {
	1: "res://scenes/niveles/nivel_1.tscn",
	2: "res://scenes/niveles/nivel_2.tscn",
}

# Volúmenes lineales (0.0 a 1.0) de cada bus de audio
var volumen_general: float = 0.8
var volumen_musica: float = 0.6
var volumen_efectos: float = 0.8

var nivel_actual: int = 1

#region Puntaje
## Puntaje de la partida en curso. Al pasar al nivel 2 NO se reinicia:
## el nivel 2 arranca con lo que se juntó en el nivel 1.
var puntaje: int = 0
## Puntaje con el que se empezó el nivel actual (para "Reintentar")
var puntaje_inicio_nivel: int = 0
## Mejor puntaje de todas las partidas (se guarda en el archivo)
var puntaje_maximo: int = 0
## Puntaje con el que se llega a cada nivel { 2: 3450 } (se guarda en el archivo).
## Así, si pasaste el nivel 1 y cerrás el juego, al volver y elegir el
## nivel 2 arrancás con el puntaje que traías.
var puntaje_al_llegar: Dictionary = {}
#endregion

var mejores_tiempos: Dictionary = {}  # { 1: 35.2, 2: 90.8 }

var archivo_de_guardado = "user://hotline_zombies.dat"


func _ready() -> void:
	# El Global nunca se pausa (lo necesitamos para salir de la pausa)
	process_mode = Node.PROCESS_MODE_ALWAYS
	cargar()
	aplicar_volumenes()


#region Audio

func aplicar_volumenes() -> void:
	_aplicar_bus("Master", volumen_general)
	_aplicar_bus("Musica", volumen_musica)
	_aplicar_bus("Efectos", volumen_efectos)


func _aplicar_bus(nombre_bus: String, valor: float) -> void:
	var indice = AudioServer.get_bus_index(nombre_bus)
	if indice == -1:
		return
	# Los buses trabajan en decibeles, por eso convertimos el valor lineal
	AudioServer.set_bus_volume_db(indice, linear_to_db(max(valor, 0.0001)))
	AudioServer.set_bus_mute(indice, valor <= 0.001)

#endregion


#region Cambios de escena (todos pasan por el fundido a negro)

## Desde el MENÚ: el nivel 1 arranca de cero; el nivel 2 arranca con el
## puntaje guardado al terminar el nivel 1 (si existe).
func empezar_desde_menu(numero: int) -> void:
	puntaje = puntaje_al_llegar.get(numero, 0) if numero > 1 else 0
	puntaje_inicio_nivel = puntaje
	ir_al_nivel(numero)


func ir_al_nivel(numero: int) -> void:
	if not NIVELES.has(numero):
		ir_al_menu()
		return
	nivel_actual = numero
	Transicion.cambiar_escena(NIVELES[numero])


## Reintentar: volvemos al puntaje que teníamos al empezar el nivel
func reintentar_nivel() -> void:
	puntaje = puntaje_inicio_nivel
	ir_al_nivel(nivel_actual)


## Pasar de nivel: el puntaje se ARRASTRA al siguiente nivel
func ir_al_siguiente_nivel() -> void:
	puntaje_inicio_nivel = puntaje
	ir_al_nivel(nivel_actual + 1)


func hay_siguiente_nivel() -> bool:
	return NIVELES.has(nivel_actual + 1)


func ir_al_menu() -> void:
	Input.set_custom_mouse_cursor(null)
	Transicion.cambiar_escena(ESCENA_MENU)

#endregion


#region Puntaje y récords

func sumar_puntos(cantidad: int) -> void:
	puntaje += cantidad


## Se llama al superar un nivel. Devuelve true si el tiempo es récord.
func completar_nivel(numero_nivel: int, tiempo: float) -> bool:
	var es_record_tiempo = false
	if not mejores_tiempos.has(numero_nivel) or tiempo < mejores_tiempos[numero_nivel]:
		mejores_tiempos[numero_nivel] = tiempo
		es_record_tiempo = true
	# guardamos con cuántos puntos se llega al siguiente nivel
	if NIVELES.has(numero_nivel + 1):
		puntaje_al_llegar[numero_nivel + 1] = puntaje
	actualizar_puntaje_maximo()
	grabar()
	return es_record_tiempo


## Devuelve true si el puntaje actual superó al récord (y lo guarda)
func actualizar_puntaje_maximo() -> bool:
	if puntaje > puntaje_maximo:
		puntaje_maximo = puntaje
		grabar()
		return true
	return false


func formatear_tiempo(tiempo: float) -> String:
	var minutos = int(tiempo) / 60
	var segundos = fmod(tiempo, 60.0)
	return "%02d:%05.2f" % [minutos, segundos]

#endregion


#region Guardado en archivo (FileAccess + store_var, como en el primer parcial)

func grabar() -> void:
	var archivo = FileAccess.open(archivo_de_guardado, FileAccess.WRITE)
	if archivo == null:
		return
	archivo.store_var({
		"volumen_general": volumen_general,
		"volumen_musica": volumen_musica,
		"volumen_efectos": volumen_efectos,
		"mejores_tiempos": mejores_tiempos,
		"puntaje_maximo": puntaje_maximo,
		"puntaje_al_llegar": puntaje_al_llegar,
	})
	archivo.close()


func cargar() -> void:
	# Primero nos fijamos si el archivo existe, si no, quedan los valores por defecto
	if not FileAccess.file_exists(archivo_de_guardado):
		return
	var archivo = FileAccess.open(archivo_de_guardado, FileAccess.READ)
	if archivo == null:
		return
	var datos = archivo.get_var()
	archivo.close()
	if typeof(datos) != TYPE_DICTIONARY:
		return
	volumen_general = datos.get("volumen_general", volumen_general)
	volumen_musica = datos.get("volumen_musica", volumen_musica)
	volumen_efectos = datos.get("volumen_efectos", volumen_efectos)
	mejores_tiempos = datos.get("mejores_tiempos", {})
	puntaje_maximo = datos.get("puntaje_maximo", 0)
	puntaje_al_llegar = datos.get("puntaje_al_llegar", {})

#endregion
