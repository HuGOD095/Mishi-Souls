extends ColorRect

@onready var btn_reanudar: Button = $VBoxContainer/Reanudar
@onready var btn_reiniciar: Button = $VBoxContainer/Reiniciar
@onready var btn_salir: Button = $VBoxContainer/Salir

func _ready() -> void:
	visible = false
	btn_reanudar.pressed.connect(alternar_pausa)
	btn_reiniciar.pressed.connect(_reiniciar_nivel)
	btn_salir.pressed.connect(_salir_juego)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pausa"):
		alternar_pausa()
		get_viewport().set_input_as_handled()

func alternar_pausa() -> void:
	var pausado := not get_tree().paused
	get_tree().paused = pausado
	visible = pausado
	
	if not OS.has_feature("mobile"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if pausado else Input.MOUSE_MODE_CAPTURED

func _reiniciar_nivel() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _salir_juego() -> void:
	get_tree().paused = false
	get_tree().quit()
