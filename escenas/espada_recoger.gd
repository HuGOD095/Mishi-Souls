extends Area3D
@export var velocidad_giro := 2.0
@export var amplitud_flotacion := 0.15
@export var velocidad_flotacion := 3.0

@onready var modelo_espada: Node3D = $Sword1
var tiempo := 0.0
var altura_inicial := 0.0

func _ready():
	altura_inicial = modelo_espada.position.y
	body_entered.connect(_al_entrar_cuerpo)
	

func _process(delta: float):
	tiempo += delta
	modelo_espada.rotate_y(velocidad_giro * delta)
	modelo_espada.position.y = altura_inicial + sin(tiempo * velocidad_flotacion) * amplitud_flotacion

func _al_entrar_cuerpo(body: Node3D):
	if body.has_method("recoger_espada"):
		body.recoger_espada()
		queue_free()
