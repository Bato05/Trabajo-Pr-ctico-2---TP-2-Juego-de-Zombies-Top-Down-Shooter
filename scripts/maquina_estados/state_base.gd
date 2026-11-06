class_name StateBase extends Node

## Clase base de todos los estados.

## referencia al nodo que vamos a controlar
var controlled_node: Node

## referencia a la maquina de estados
var state_machine: StateMachine


#region métodos comunes

## método que se ejecuta al entrar en el estado
func start() -> void:
	pass


## método que se ejecuta al abandonar el estado
func end() -> void:
	pass

#endregion
