extends CharacterBody3D

@export var velocidad := 6.0
@export var velocidad_correr := 10.0
@export var fuerza_salto := 5.5
@export var sensibilidad_mouse := 0.003

@export_range(-90.0, 0.0) var limite_abajo_grados := -45.0
@export_range(0.0, 90.0) var limite_arriba_grados := 45.0

@onready var pivote_camara: SpringArm3D = $PivoteCamara
@onready var modelo_mishi: Node3D = $Mishi_Animaciones
@onready var anim_player: AnimationPlayer = $Mishi_Animaciones/AnimationPlayer

var gravedad: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var atacando: bool = false
var haciendo_emote: bool = false
var tiene_espada: bool = false
var espada_equipada: bool = false

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	anim_player.animation_finished.connect(_al_terminar_animacion)
	anim_player.play("IdleNormal")
	modelo_mishi.ocultar_todas()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * sensibilidad_mouse)
		pivote_camara.rotate_x(-event.relative.y * sensibilidad_mouse)
		pivote_camara.rotation.x = clamp(
			pivote_camara.rotation.x,
			deg_to_rad(limite_abajo_grados),
			deg_to_rad(limite_arriba_grados)
		)

	# Liberar o capturar ratón
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return
	elif event is InputEventMouseButton and event.pressed and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return

	# Atacar con clic izquierdo
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and is_on_floor() and not atacando:
			haciendo_emote = false
			atacando = true
			anim_player.play("SwordAttack", 0.1)

	if event is InputEventKey and event.pressed and not event.echo:
		# Tecla E: alternar espada entre la espalda y la mano
		if event.keycode == KEY_E and tiene_espada and not atacando:
			espada_equipada = not espada_equipada
			if espada_equipada:
				modelo_mishi.mostrar_en_mano()
			else:
				modelo_mishi.mostrar_en_espalda()

		# Tecla 1: emote cancelable
		elif event.keycode == KEY_1 and is_on_floor() and not atacando:
			haciendo_emote = true
			anim_player.play("SambaDanceEmote", 0.15)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravedad * delta

	var input_dir := Input.get_vector("left", "right", "up", "down")
	var quiere_saltar := Input.is_action_just_pressed("jump") and is_on_floor()

	if haciendo_emote and (input_dir != Vector2.ZERO or quiere_saltar):
		haciendo_emote = false

	if quiere_saltar and not atacando:
		velocity.y = fuerza_salto
		anim_player.play("Jumping")

	var direccion := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	var esta_corriendo := Input.is_key_pressed(KEY_SHIFT) and direccion != Vector3.ZERO
	var velocidad_actual := velocidad_correr if esta_corriendo else velocidad

	if direccion and not atacando:
		velocity.x = direccion.x * velocidad_actual
		velocity.z = direccion.z * velocidad_actual
	else:
		velocity.x = move_toward(velocity.x, 0, velocidad_actual)
		velocity.z = move_toward(velocity.z, 0, velocidad_actual)

	move_and_slide()
	_actualizar_animacion(direccion, esta_corriendo)

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

func _al_terminar_animacion(nombre_animacion: String) -> void:
	if nombre_animacion == "SwordAttack":
		atacando = false
	elif nombre_animacion == "SambaDanceEmote":
		haciendo_emote = false
