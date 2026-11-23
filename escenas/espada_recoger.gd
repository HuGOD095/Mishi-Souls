extends Area3D
@export var velocidad_giro := 2.0
@export var amplitud_flotacion := 0.15
@export var velocidad_flotacion := 3.0

@onready var modelo_espada: Node3D = $Sword1
@onready var colision: CollisionShape3D = $CollisionShape3D
@onready var aura_espada: AudioStreamPlayer3D = $AuraEspada
@onready var sonido_recoger: AudioStreamPlayer = $SonidoRecoger
var tiempo := 0.0
var altura_inicial := 0.0
var ya_recogida: bool = false

func _ready():
	altura_inicial = modelo_espada.position.y
	body_entered.connect(_al_entrar_cuerpo)
	

func _process(delta: float):
	if ya_recogida:
		return
	tiempo += delta
	modelo_espada.rotate_y(velocidad_giro * delta)
	modelo_espada.position.y = altura_inicial + sin(tiempo * velocidad_flotacion) * amplitud_flotacion

func _al_entrar_cuerpo(body: Node3D):
	if ya_recogida:
		return
	if body.has_method("recoger_espada"):
		ya_recogida = true
		
		aura_espada.stop()
		colision.set_deferred("disabled", true)
		visible = false
		body.recoger_espada()
		sonido_recoger.play()
		await sonido_recoger.finished
		queue_free()
