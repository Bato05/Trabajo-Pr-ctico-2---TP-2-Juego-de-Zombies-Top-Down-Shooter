class_name StateMachine extends Node

## Máquina de estados (la misma idea que en el proyecto "Maquina-de-estados").
## Cada hijo de este nodo es un estado (StateBase). La máquina le pasa
## los callbacks de Godot SOLO al estado activo.

## nodo que vamos a controlar (la raíz de la escena: Jugador o un Enemigo)
@onready var controlled_node = self.owner

## estado por defecto
@export var default_state: StateBase

## si está activo, imprime en consola cada cambio de estado
@export var debug: bool = false

## estado en ejecución en cada momento
var current_state: StateBase = null


func _ready() -> void:
	call_deferred("_state_default_start")


func _state_default_start() -> void:
	current_state = default_state
	_state_start()


## método para cambiar a un nuevo estado (por nombre de nodo)
func change_to(new_state: String) -> void:
	if not has_node(new_state):
		push_warning("StateMachine: no existe el estado " + new_state)
		return
	if current_state and current_state.has_method("end"):
		current_state.end()
	current_state = get_node(new_state)
	_state_start()


## nombre del estado actual (útil para consultas desde afuera)
func current_state_name() -> String:
	return current_state.name if current_state else ""


## prepara las variables del nuevo estado y lanza su start
func _state_start() -> void:
	if current_state == null:
		return
	if debug:
		prints("StateMachine", controlled_node.name, "start state", current_state.name)
	current_state.controlled_node = controlled_node
	current_state.state_machine = self
	current_state.start()


#region sobreescribimos los metodos de godot del nodo

func _process(delta: float) -> void:
	if current_state and current_state.has_method("on_process"):
		current_state.on_process(delta)


func _physics_process(delta: float) -> void:
	if current_state and current_state.has_method("on_physics_process"):
		current_state.on_physics_process(delta)


func _unhandled_input(event: InputEvent) -> void:
	if current_state and current_state.has_method("on_unhandled_input"):
		current_state.on_unhandled_input(event)

#endregion
