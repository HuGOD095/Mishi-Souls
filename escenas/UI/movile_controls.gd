extends CanvasLayer

func _process(_delta: float) -> void:
	var en_pausa := get_tree().paused
	$Buttons.visible = not en_pausa
	$Joystick.visible = not en_pausa
	$Buttons.process_mode = Node.PROCESS_MODE_DISABLED if en_pausa else Node.PROCESS_MODE_INHERIT
	$Joystick.process_mode = Node.PROCESS_MODE_DISABLED if en_pausa else Node.PROCESS_MODE_INHERIT
