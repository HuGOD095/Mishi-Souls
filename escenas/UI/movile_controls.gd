extends CanvasLayer

var es_movil := OS.has_feature("mobile") or DisplayServer.is_touchscreen_available()

func _ready() -> void:
	if not es_movil:
		visible = false
		process_mode = Node.PROCESS_MODE_DISABLED

func _process(_delta: float) -> void:
	if not es_movil:
		return
		
	var en_pausa := get_tree().paused
	$Buttons.visible = not en_pausa
	$Joystick.visible = not en_pausa
	$Buttons.process_mode = Node.PROCESS_MODE_DISABLED if en_pausa else Node.PROCESS_MODE_INHERIT
	$Joystick.process_mode = Node.PROCESS_MODE_DISABLED if en_pausa else Node.PROCESS_MODE_INHERIT
