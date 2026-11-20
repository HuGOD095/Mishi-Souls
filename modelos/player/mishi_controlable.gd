extends Node3D

@onready var espada_espalda: Node3D = %EspadaEspalda
@onready var espada_mano: Node3D = %EspadaMano

func mostrar_en_espalda() -> void:
	espada_espalda.visible = true
	espada_mano.visible = false

func mostrar_en_mano() -> void:
	espada_espalda.visible = false
	espada_mano.visible = true

func ocultar_todas() -> void:
	espada_espalda.visible = false
	espada_mano.visible = false
