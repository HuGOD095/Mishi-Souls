extends CharacterBody3D

signal vida_cambiada(vida_actual: int, vida_maxima: int)
signal jugador_murio
signal estamina_cambiada(actual: float, maxima: float)

var juego_ganado: bool = false
var riel_escalera: PathFollow3D = null
var velocidad_escalera: float = 4.5

var velocidad_caida_segura: float = 20.0
var velocidad_caida_mortal: float = 24.0

var vida_maxima: int = 10
var tiempo_invulnerable: float = 1.2
var velocidad := 6.0
var velocidad_correr := 10.0
var fuerza_salto := 5.5
var sensibilidad_mouse := 0.003
var dano_espada: int = 3
var dano_sin_arma: int = 1
var velocidad_ataque: float = 1.5
var retraso_golpe: float = 0.6
var duracion_golpe: float = 0.25
var estamina_maxima: float = 100.0
var gasto_correr: float = 25.0
var regeneracion_estamina: float = 20.0
var retraso_regeneracion: float = 1.0
var estamina_actual: float
var tiempo_sin_gastar: float = 0.0
var agotado: bool = false

@export_range(-90.0, 0.0) var limite_abajo_grados := -45.0
@export_range(0.0, 90.0) var limite_arriba_grados := 45.0

@onready var pivote_camara: SpringArm3D = $PivoteCamara
@onready var modelo_mishi: Node3D = $Mishi_Animaciones
@onready var anim_player: AnimationPlayer = $Mishi_Animaciones/AnimationPlayer
@onready var hitbox_espada: Area3D = $GolpeEspada

# Nodos de audio del jugador
@onready var sonido_caminata: AudioStreamPlayer = $SFX/SonidoCaminata
@onready var sonido_escaleras: AudioStreamPlayer = $SFX/SonidoEscaleras
@onready var sonido_salto: AudioStreamPlayer = $SFX/SonidoSalto
@onready var sonido_espadazo: AudioStreamPlayer = $SFX/SonidoEspadazo
@onready var sonido_dano: AudioStreamPlayer = $SFX/SonidoDano

var vida_actual: int
var es_invulnerable: bool = false
var esta_muerto: bool = false
var gravedad: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var atacando: bool = false
var haciendo_emote: bool = false
var tiene_espada: bool = false
var espada_equipada: bool = false
var enemigos_golpeados: Array[Node3D] = []

func _ready() -> void:
	_conectar_escaleras.call_deferred()
	
	vida_actual = vida_maxima
	vida_cambiada.emit(vida_actual, vida_maxima)
	
	estamina_actual = estamina_maxima
	estamina_cambiada.emit(estamina_actual, estamina_maxima)
	
	hitbox_espada.monitoring = false
	hitbox_espada.body_entered.connect(_on_hitbox_espada_body_entered)
	if not OS.has_feature("mobile"):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	anim_player.animation_finished.connect(_al_terminar_animacion)
	anim_player.play("IdleNormal")
	modelo_mishi.ocultar_todas()

func _conectar_escaleras() -> void:
	for escalera in get_tree().get_nodes_in_group("escaleras_path"):
		var seguidor: PathFollow3D = escalera.get_node_or_null("Riel/Seguidor")
		var entrada_abajo: Area3D = escalera.get_node_or_null("EntradaAbajo")
		var entrada_arriba: Area3D = escalera.get_node_or_null("EntradaArriba")
		
		if seguidor and entrada_abajo and entrada_arriba:
			entrada_abajo.body_entered.connect(func(body: Node3D): _entrar_escalera(body, seguidor, 0.03))
			entrada_arriba.body_entered.connect(func(body: Node3D): _entrar_escalera(body, seguidor, 0.97))

func _entrar_escalera(body: Node3D, seguidor: PathFollow3D, inicio_ratio: float) -> void:
	if body == self and riel_escalera == null and not esta_muerto:
		riel_escalera = seguidor
		riel_escalera.progress_ratio = inicio_ratio
		global_position = riel_escalera.global_position
		velocity = Vector3.ZERO
		atacando = false
		haciendo_emote = false
		sonido_caminata.stop()

func _soltar_escalera() -> void:
	riel_escalera = null
	anim_player.speed_scale = 1.0
	velocity = Vector3.ZERO
	sonido_escaleras.stop()

func _unhandled_input(event: InputEvent) -> void:
	if esta_muerto or juego_ganado:
		return
		
	# 1. Cámara con ratón (PC)
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * sensibilidad_mouse)
		pivote_camara.rotate_x(-event.relative.y * sensibilidad_mouse)
		pivote_camara.rotation.x = clamp(
			pivote_camara.rotation.x,
			deg_to_rad(limite_abajo_grados),
			deg_to_rad(limite_arriba_grados)
		)
	# 2. Cámara táctil (Android - arrastrar en cualquier zona libre de la pantalla)
	elif event is InputEventScreenDrag:
		var sensibilidad_tactil := sensibilidad_mouse * 1.8
		rotate_y(-event.relative.x * sensibilidad_tactil)
		pivote_camara.rotate_x(-event.relative.y * sensibilidad_tactil)
		pivote_camara.rotation.x = clamp(
			pivote_camara.rotation.x,
			deg_to_rad(limite_abajo_grados),
			deg_to_rad(limite_arriba_grados)
		)

	# Liberar o capturar ratón en PC
	if not OS.has_feature("mobile"):
		if event.is_action_pressed("ui_cancel"):
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			return
		elif event is InputEventMouseButton and event.pressed and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			return

	if riel_escalera != null:
		return

# Atacar (botón táctil "atacar" o clic izquierdo en PC)
	if event.is_action_pressed("atacar"):
		# En móvil, ignorar si el evento viene emulado como clic de ratón
		if OS.has_feature("mobile") and event is InputEventMouseButton:
			return
			
		var permiso_pc := OS.has_feature("mobile") or Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
		if permiso_pc and is_on_floor() and not atacando:
			haciendo_emote = false
			atacando = true
			enemigos_golpeados.clear()
			sonido_caminata.stop()
			anim_player.play("SwordAttack", 0.1, velocidad_ataque)
			_activar_hitbox_sincronizada()

	# Equipar / guardar espada (botón táctil "equip" o tecla E)
	if event.is_action_pressed("equip") and tiene_espada and not atacando:
		espada_equipada = not espada_equipada
		if espada_equipada:
			modelo_mishi.mostrar_en_mano()
		else:
			modelo_mishi.mostrar_en_espalda()

	# Emote de baile (botón táctil "emote" o tecla 1)
	elif event.is_action_pressed("emote") and is_on_floor() and not atacando:
		haciendo_emote = true
		sonido_caminata.stop()
		anim_player.play("SambaDanceEmote", 0.15)

func _physics_process(delta: float) -> void:
	if esta_muerto or juego_ganado:
		return
	
	# Movimiento exacto sobre el riel de la escalera
	if riel_escalera != null:
		var dir_escalera := Input.get_axis("up", "down") # -1 con W (subir), +1 con S (bajar)
		
		if dir_escalera < 0: # Subiendo (W)
			riel_escalera.progress += velocidad_escalera * delta
			global_position = riel_escalera.global_position
			if anim_player.current_animation != "ClimbingLadder" or anim_player.get_playing_speed() < 0:
				anim_player.play("ClimbingLadder")
			if not sonido_escaleras.playing:
				sonido_escaleras.pitch_scale = 1.05
				sonido_escaleras.play()
			if riel_escalera.progress_ratio >= 1.0:
				_soltar_escalera()
		elif dir_escalera > 0: # Bajando (S)
			riel_escalera.progress -= velocidad_escalera * delta
			global_position = riel_escalera.global_position
			if anim_player.current_animation != "ClimbingLadder" or anim_player.get_playing_speed() > 0:
				anim_player.play_backwards("ClimbingLadder")
			if not sonido_escaleras.playing:
				sonido_escaleras.pitch_scale = 0.95
				sonido_escaleras.play()
			if riel_escalera.progress_ratio <= 0.0:
				_soltar_escalera()
		else: # Quieto agarrado a la escalera
			if anim_player.current_animation == "ClimbingLadder":
				anim_player.pause()
			if sonido_escaleras.playing:
				sonido_escaleras.stop()
		return
	
	if not is_on_floor():
		velocity.y -= gravedad * delta

	var input_dir := Input.get_vector("left", "right", "up", "down")
	var quiere_saltar := Input.is_action_just_pressed("jump") and is_on_floor()

	if haciendo_emote and (input_dir != Vector2.ZERO or quiere_saltar):
		haciendo_emote = false

	if quiere_saltar and not atacando:
		velocity.y = fuerza_salto
		anim_player.play("Jumping")
		sonido_caminata.stop()
		sonido_salto.pitch_scale = randf_range(0.95, 1.05)
		sonido_salto.play()

	var direccion := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	var quiere_correr := Input.is_action_pressed("sprint") and direccion != Vector3.ZERO
	var puede_correr := estamina_actual > 0.0 and not agotado
	var esta_corriendo := quiere_correr and puede_correr and not atacando
	
	if esta_corriendo:
		estamina_actual = max(0.0, estamina_actual - gasto_correr * delta)
		tiempo_sin_gastar = 0.0
		if estamina_actual == 0.0:
			agotado = true
		estamina_cambiada.emit(estamina_actual, estamina_maxima)
	else:
		tiempo_sin_gastar += delta
		if tiempo_sin_gastar >= retraso_regeneracion and estamina_actual < estamina_maxima:
			estamina_actual = min(estamina_maxima, estamina_actual + regeneracion_estamina * delta)
			if estamina_actual >= estamina_maxima * 0.25:
				agotado = false
			estamina_cambiada.emit(estamina_actual, estamina_maxima)
	
	var velocidad_actual := velocidad_correr if esta_corriendo else velocidad

	if direccion and not atacando:
		velocity.x = direccion.x * velocidad_actual
		velocity.z = direccion.z * velocidad_actual
	else:
		velocity.x = move_toward(velocity.x, 0, velocidad_actual)
		velocity.z = move_toward(velocity.z, 0, velocidad_actual)
	
	# Guardar estado y velocidad vertical justo antes de aterrizar
	var estaba_en_suelo := is_on_floor()
	var velocidad_vertical_previa := velocity.y
	
	move_and_slide()
	
	# Calcular daño por caída al tocar el suelo tras una caída alta
	if not estaba_en_suelo and is_on_floor():
		var velocidad_impacto := -velocidad_vertical_previa
		if velocidad_impacto > velocidad_caida_segura:
			var proporcion := clampf(
				(velocidad_impacto - velocidad_caida_segura) / (velocidad_caida_mortal - velocidad_caida_segura),
				0.1,
				1.0
			)
			var dano_caida := int(ceil(proporcion * vida_maxima))
			_aplicar_dano_caida(dano_caida)
	
	_actualizar_animacion(direccion, esta_corriendo)
	_actualizar_sonido_pasos(direccion, esta_corriendo)

func _actualizar_sonido_pasos(direccion: Vector3, esta_corriendo: bool) -> void:
	if is_on_floor() and direccion != Vector3.ZERO and not atacando and not haciendo_emote:
		sonido_caminata.pitch_scale = 1.35 if esta_corriendo else 1.0
		if not sonido_caminata.playing:
			sonido_caminata.play()
	else:
		if sonido_caminata.playing:
			sonido_caminata.stop()

func _actualizar_animacion(direccion: Vector3, esta_corriendo: bool) -> void:
	if atacando or haciendo_emote:
		return

	if not is_on_floor():
		if anim_player.current_animation != "Jumping":
			anim_player.play("Jumping")
		return

	if direccion != Vector3.ZERO:
		var anim_objetivo := "Running" if esta_corriendo else "Walking"
		if anim_player.current_animation != anim_objetivo:
			anim_player.play(anim_objetivo, 0.15)
	else:
		if anim_player.current_animation != "IdleNormal":
			anim_player.play("IdleNormal", 0.2)

func recoger_espada() -> void:
	tiene_espada = true
	espada_equipada = false
	modelo_mishi.mostrar_en_espalda()

func _activar_hitbox_sincronizada() -> void:
	await get_tree().create_timer(retraso_golpe / velocidad_ataque).timeout
	if not atacando:
		return
	
	# Reproducir el corte de aire justo en el instante en que inicia el tajo
	sonido_espadazo.pitch_scale = randf_range(0.95, 1.08) if espada_equipada else 1.25
	sonido_espadazo.play()
	hitbox_espada.monitoring = true
	
	await get_tree().create_timer(duracion_golpe / velocidad_ataque).timeout
	hitbox_espada.monitoring = false

func _al_terminar_animacion(nombre_animacion: String) -> void:
	if nombre_animacion == "SwordAttack":
		atacando = false
		hitbox_espada.monitoring = false
	elif nombre_animacion == "SambaDanceEmote":
		haciendo_emote = false

func _on_hitbox_espada_body_entered(body: Node3D) -> void:
	if body.is_in_group("enemigos") and body not in enemigos_golpeados:
		enemigos_golpeados.append(body)
		if body.has_method("recibir_dano"):
			var dano_actual := dano_espada if espada_equipada else dano_sin_arma
			body.recibir_dano(dano_actual)

func recibir_dano(cantidad: int = 1) -> void:
	if esta_muerto or es_invulnerable or juego_ganado:
		return
	
	vida_actual = max(0, vida_actual - cantidad)
	vida_cambiada.emit(vida_actual, vida_maxima)
	sonido_dano.pitch_scale = randf_range(0.95, 1.05)
	sonido_dano.play()
	
	if vida_actual <= 0:
		_morir()
	else:
		_activar_invulnerabilidad()

func _aplicar_dano_caida(cantidad: int) -> void:
	if esta_muerto or juego_ganado:
		return
	
	vida_actual = max(0, vida_actual - cantidad)
	vida_cambiada.emit(vida_actual, vida_maxima)
	sonido_dano.pitch_scale = 0.9
	sonido_dano.play()
	
	if vida_actual <= 0:
		_morir()
	else:
		_activar_invulnerabilidad()

func _activar_invulnerabilidad() -> void:
	es_invulnerable = true
	var tiempo_transcurrido := 0.0
	while tiempo_transcurrido < tiempo_invulnerable and not esta_muerto:
		modelo_mishi.visible = not modelo_mishi.visible
		await get_tree().create_timer(0.1).timeout
		tiempo_transcurrido += 0.1
	
	modelo_mishi.visible = true
	es_invulnerable = false

func _morir() -> void:
	esta_muerto = true
	riel_escalera = null
	atacando = false
	hitbox_espada.monitoring = false
	velocity = Vector3.ZERO
	sonido_caminata.stop()
	sonido_escaleras.stop()
	
	$CollisionShape3D.set_deferred("disabled", true)
	if modelo_mishi.has_method("activar_ragdoll"):
		modelo_mishi.activar_ragdoll()
	
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	jugador_murio.emit()

func ganar_juego() -> void:
	juego_ganado = true
	riel_escalera = null
	atacando = false
	hitbox_espada.monitoring = false
	velocity = Vector3.ZERO
	sonido_caminata.stop()
	sonido_escaleras.stop()
	anim_player.play("SambaDanceEmote", 0.2) 
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
