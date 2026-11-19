extends CharacterBody3D

@export var velocidad := 6.0
@export var fuerza_salto := 5.5
@export var sensibilidad_mouse := 0.003

@export_range(-90.0, 0.0) var limite_abajo_grados := -45.0
@export_range(0.0, 90.0) var limite_arriba_grados := 45.0

@onready var pivote_camara: Node3D = $Camera3D

var gravedad: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready() -> void:
	# Captura y oculta el cursor al iniciar la prueba
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * sensibilidad_mouse)
		pivote_camara.rotate_x(-event.relative.y * sensibilidad_mouse)
		
		# Aplica el tope mínimo (hacia abajo) y máximo (hacia arriba)
		pivote_camara.rotation.x = clamp(
			pivote_camara.rotation.x,
			deg_to_rad(limite_abajo_grados),
			deg_to_rad(limite_arriba_grados)
		)

	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	# Liberar el mouse con Escape o volver a capturarlo al hacer clic
	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravedad * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = fuerza_salto

	# Movimiento lateral (A/D) y frontal (W/S) relativo hacia donde apunta el personaje
	var input_dir := Input.get_vector("left", "right", "up", "down")
	var direccion := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direccion:
		velocity.x = direccion.x * velocidad
		velocity.z = direccion.z * velocidad
	else:
		velocity.x = move_toward(velocity.x, 0, velocidad)
		velocity.z = move_toward(velocity.z, 0, velocidad)

	move_and_slide()
