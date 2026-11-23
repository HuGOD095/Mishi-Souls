extends CharacterBody3D

@export var vida: int = 3
@export var dano_contacto: int = 1
@export var velocidad: float = 5.8
@export var distancia_deteccion: float = 25
@export var distancia_despawn: float = 55.0 # Se borra si te alejas más de esto
@export var altura_flotacion: float = 0.4

@onready var malla: Node3D = $MallaEspectro
@onready var area_ataque: Area3D = $AreaAtaque
@onready var colision: CollisionShape3D = $CollisionShape3D
@onready var sonido_aparicion: AudioStreamPlayer3D = $SonidoAparicion
@onready var sonido_ataque_muerte: AudioStreamPlayer3D = $SonidoAtaqueMuerte

var jugador: Node3D = null
var tiempo: float = 0.0
var esta_muriendo: bool = false

func _ready() -> void:
	area_ataque.body_entered.connect(_on_area_ataque_body_entered)
	jugador = get_tree().get_first_node_in_group("player")
	tiempo = randf() * 10.0
	# Variar ligeramente el tono (pitch) al aparecer para que cada espectro suene distinto
	sonido_aparicion.pitch_scale = randf_range(0.9, 1.1)

func _physics_process(delta: float) -> void:
	if esta_muriendo:
		return
		
	tiempo += delta
	
	# Oscilación del espectro
	malla.position.y = altura_flotacion + sin(tiempo * 3.0) * 0.15
	malla.rotation.z = sin(tiempo * 2.0) * 0.06
	
	if not jugador:
		return
	
	# Calcular distancia real 3D hacia el jugador
	var distancia_real := global_position.distance_to(jugador.global_position)
	
	# Si el jugador se alejó demasiado, desaparecer para liberar cupo de spawn
	if distancia_real > distancia_despawn:
		queue_free()
		return
	
	# Cálculo de persecución
	var pos_objetivo := Vector3(jugador.global_position.x, global_position.y, jugador.global_position.z)
	var direccion := global_position.direction_to(pos_objetivo)
	var distancia := global_position.distance_to(pos_objetivo)
	
	if distancia <= distancia_deteccion and distancia > 0.8:
		velocity.x = direccion.x * velocidad
		velocity.z = direccion.z * velocidad
		
		var punto_mirar := Vector3(jugador.global_position.x, global_position.y, jugador.global_position.z)
		look_at(punto_mirar, Vector3.UP)
	else:
		velocity.x = move_toward(velocity.x, 0.0, velocidad * delta * 5.0)
		velocity.z = move_toward(velocity.z, 0.0, velocidad * delta * 5.0)
	
	velocity.y = (jugador.global_position.y - global_position.y) * 2.0
	
	move_and_slide()
	
	for cuerpo in area_ataque.get_overlapping_bodies():
		if cuerpo.is_in_group("player") and cuerpo.has_method("recibir_dano"):
			cuerpo.recibir_dano(dano_contacto)
			if not sonido_ataque_muerte.playing:
				sonido_ataque_muerte.pitch_scale = randf_range(0.95, 1.05)
				sonido_ataque_muerte.play()

func recibir_dano(cantidad: int = 1):
	if esta_muriendo:
		return
		
	vida -= cantidad
	if vida <= 0:
		_morir()

func _morir() -> void:
	esta_muriendo = true
	
	# Quitarlo del grupo "enemigos" para que el spawner ya libere su cupo y no bloquee la victoria
	remove_from_group("enemigos")
	
	# Desactivar colisiones, área de ataque y ocultarlo visualmente
	colision.set_deferred("disabled", true)
	area_ataque.set_deferred("monitoring", false)
	malla.visible = false
	
	# Reproducir sonido de desaparición completo antes de destruir el nodo
	sonido_aparicion.stop()
	sonido_ataque_muerte.pitch_scale = randf_range(0.85, 1.0)
	sonido_ataque_muerte.play()
	await sonido_ataque_muerte.finished
	queue_free()

func _on_area_ataque_body_entered(body: Node3D):
	if esta_muriendo:
		return
	if body.is_in_group("player") and body.has_method("recibir_dano"):
		body.recibir_dano(dano_contacto)
		if not sonido_ataque_muerte.playing:
			sonido_ataque_muerte.pitch_scale = randf_range(0.95, 1.05)
			sonido_ataque_muerte.play()
