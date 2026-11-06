extends Node2D

## BALA - en lugar de un Area2D usamos un RAYO por frame (intersect_ray).
## Así una bala rápida nunca "atraviesa" una pared o puerta finita.

@export var velocidad: float = 1500.0
@export var danio: int = 1
@export var tiempo_de_vida: float = 1.2

## capas con las que choca: 1 mundo + 3 zombies + 4 puertas
const MASCARA_COLISION = 1 | 4 | 8

var direccion: Vector2 = Vector2.RIGHT
var origen = null  ## Vector2 opcional: desde dónde sale el primer rayo
var tiempo: float = 0.0


func _ready() -> void:
	rotation = direccion.angle()


func _physics_process(delta: float) -> void:
	tiempo += delta
	if tiempo >= tiempo_de_vida:
		queue_free()
		return

	var desde: Vector2 = global_position
	if origen != null:
		desde = origen
		origen = null
	var hasta: Vector2 = global_position + direccion * velocidad * delta

	var consulta = PhysicsRayQueryParameters2D.create(desde, hasta, MASCARA_COLISION)
	var resultado = get_world_2d().direct_space_state.intersect_ray(consulta)

	if resultado:
		global_position = resultado.position
		var golpeado = resultado.collider
		if golpeado is Enemigo:
			golpeado.recibir_disparo(danio, direccion)
		else:
			_chispas(resultado.normal)
		queue_free()
		return

	global_position = hasta


func _chispas(normal: Vector2) -> void:
	var particulas = CPUParticles2D.new()
	particulas.one_shot = true
	particulas.emitting = false
	particulas.amount = 6
	particulas.lifetime = 0.25
	particulas.explosiveness = 1.0
	particulas.direction = normal
	particulas.spread = 50.0
	particulas.initial_velocity_min = 80.0
	particulas.initial_velocity_max = 200.0
	particulas.scale_amount_min = 2.0
	particulas.scale_amount_max = 3.0
	particulas.color = Color(1.0, 0.85, 0.4)
	particulas.global_position = global_position
	get_tree().current_scene.add_child(particulas)
	particulas.emitting = true
	particulas.finished.connect(particulas.queue_free)
