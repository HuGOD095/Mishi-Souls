extends Area3D

signal recolectada

@onready var malla: Node3D = $Estrella_Base
@onready var colision: CollisionShape3D = $CollisionShape3D
@onready var sonido_recolectar: AudioStreamPlayer = $SonidoRecolectar
var tiempo := 0.0
var altura_base := 0.0
var ya_recolectada: bool = false

func _ready():
	altura_base = malla.position.y
	body_entered.connect(_on_body_entered)
	

func _process(delta: float):
	if ya_recolectada:
		return
	tiempo += delta
	malla.rotate_y(2.0 * delta)
	malla.position.y = altura_base + sin(tiempo * 3.0) * 0.12


func _on_body_entered(_body: Node3D):
	if ya_recolectada:
		return
	ya_recolectada = true
	colision.set_deferred("disabled", true)
	visible = false
	recolectada.emit()
	sonido_recolectar.play()
	await sonido_recolectar.finished
	queue_free()
