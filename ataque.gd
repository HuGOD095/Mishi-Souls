extends TouchScreenButton

@export var color_presionado := Color(0.6, 0.6, 0.6, 1.0)

func _ready() -> void:
	pressed.connect(_al_presionar)
	released.connect(_al_soltar)

func _al_presionar() -> void:
	modulate = color_presionado

func _al_soltar() -> void:
	modulate = Color.WHITE
