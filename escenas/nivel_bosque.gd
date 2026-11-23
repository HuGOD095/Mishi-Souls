extends Node3D
@onready var fondo_muerte: ColorRect = $UI/FondoMuerte
@onready var fade_negro: ColorRect = $UI/FadeNegro
@onready var contador_vida: ProgressBar = $UI/Vida
@onready var contador_estamina: ProgressBar = $UI/Estamina
@onready var label_contador: Label = $UI/ContadorEstrellas
@onready var label_victoria: Label = $UI/VictoryPanel
@onready var label_muerte: Label = $UI/Muerte
@onready var puntos_spawn: Node3D = $PuntosSpawn
@onready var timer_spawn: Timer = $TimerSpawn
@onready var jugador: Node3D = $PersonajePrueba

@onready var musica_bosque: AudioStreamPlayer = $SFX/MusicaBosque
@onready var ambiente_bosque: AudioStreamPlayer = $SFX/AmbienteBosque
@onready var musica_victoria: AudioStreamPlayer = $SFX/MusicaVictoria
@onready var musica_derrota: AudioStreamPlayer = $SFX/MusicaDerrota

var nivel_completado: bool = false

#enemigos
var escena_espectro: PackedScene = preload("res://escenas/enemies/enemigo_espectro.tscn")
@export var max_espectros_activos:= 5
@export var tiempo_min_spawn: float = 4.0
@export var tiempo_max_spawn: float = 8.0
@export var distancia_minima_jugador: float = 10.0
@export var distancia_maxima_jugador: float = 32.0


var estrellas_recolectadas := 0
var estrellas_totales := 0

func _ready() -> void:
	jugador.estamina_cambiada.connect(_on_jugador_estamina_cambiada)
	jugador.vida_cambiada.connect(_on_jugador_vida_cambiada)
	jugador.jugador_murio.connect(_on_jugador_murio)
	_on_jugador_vida_cambiada(jugador.vida_maxima, jugador.vida_maxima)
	_on_jugador_estamina_cambiada(jugador.estamina_maxima, jugador.estamina_maxima)
	get_viewport().scaling_3d_scale = 0.25
	label_victoria.visible = false
	label_muerte.visible = false
	fade_negro.color = Color(0, 0, 0, 1)
	create_tween().tween_property(fade_negro, "color:a", 0.0, 0.8)
	
	# buscar estrellas en el mundo
	var lista_estrellas = get_tree().get_nodes_in_group("estrellas")
	estrellas_totales = lista_estrellas.size()
	
	for estrella in lista_estrellas:
		estrella.recolectada.connect(_on_estrella_recolectada)
	
	_actualizar_texto_contador()
	
	# conectar el generador de enemigos
	timer_spawn.timeout.connect(_on_timer_spawn_timeout)
	timer_spawn.wait_time = 2.0
	timer_spawn.start()
	
func _on_estrella_recolectada():
	estrellas_recolectadas += 1
	_actualizar_texto_contador()
	
	if estrellas_recolectadas >= estrellas_totales:
		_ganar_nivel()

func _actualizar_texto_contador():
	label_contador.text = "%d / %d" % [estrellas_recolectadas, estrellas_totales]
	

func _programar_siguiente_spawn():
	timer_spawn.wait_time = randf_range(tiempo_min_spawn, tiempo_max_spawn)
	timer_spawn.start()

func _on_timer_spawn_timeout():
	var enemigos_activos = get_tree().get_nodes_in_group("enemigos").size()
	
	if escena_espectro and enemigos_activos < max_espectros_activos:
		_invocar_espectro_aleatorio()
	_programar_siguiente_spawn()

func _invocar_espectro_aleatorio():
	var marcadores = puntos_spawn.get_children()
	if marcadores.is_empty():
		return
		
	var puntos_validos: Array[Node3D] = []
	for m in marcadores:
		if m is Node3D:
			var dist: float = m.global_position.distance_to(jugador.global_position)
			if dist >= distancia_minima_jugador and dist <= distancia_maxima_jugador:
				puntos_validos.append(m)
				
	if puntos_validos.is_empty():
		return
	
	# Ordenar de más cercano a más lejano respecto al jugador
	puntos_validos.sort_custom(func(a: Node3D, b: Node3D) -> bool:
		return a.global_position.distance_to(jugador.global_position) < b.global_position.distance_to(jugador.global_position)
	)
	
	# Elegir al azar solo entre los 3 más cercanos para que siempre aparezcan en tu zona
	var candidatos := puntos_validos.slice(0, min(3, puntos_validos.size()))
	var punto_elegido: Node3D = candidatos.pick_random()
	
	var nuevo_espectro = escena_espectro.instantiate()
	nuevo_espectro.add_to_group("enemigos")
	add_child(nuevo_espectro)
	nuevo_espectro.global_position = punto_elegido.global_position
	
func _ganar_nivel():
	if nivel_completado or jugador.esta_muerto:
		return
	nivel_completado = true
	
	# musica
	musica_bosque.stop()
	ambiente_bosque.stop()
	musica_victoria.play()
	
	timer_spawn.stop()
	for enemigo in get_tree().get_nodes_in_group("enemigos"):
		enemigo.queue_free()
	if jugador.has_method("ganar_juego"):
		jugador.ganar_juego()
	label_victoria.modulate.a = 0.0
	label_victoria.visible = true
	var tween := create_tween()
	tween.tween_property(label_victoria, "modulate:a", 1.0, 0.6)
	tween.tween_interval(3.0) # Tiempo leyendo la victoria antes de cerrar
	tween.tween_property(fade_negro, "color:a", 1.0, 1.2)
	tween.tween_interval(0.3)
	# Reinicia el nivel o cierra el ejecutable (usa get_tree().quit() si prefieres que se cierre)
	tween.tween_callback(get_tree().reload_current_scene)

func _on_jugador_vida_cambiada(vida_actual: int, vida_maxima: int):
	contador_vida.max_value = vida_maxima
	contador_vida.value = vida_actual
func _on_jugador_estamina_cambiada(estamina_actual: int, estamina_maxima: int):
	contador_estamina.max_value = estamina_maxima
	contador_estamina.value = estamina_actual
	
func _on_jugador_murio() -> void:
	if nivel_completado:
		return
	# musica
	musica_bosque.stop()
	ambiente_bosque.stop()
	musica_derrota.play()
	# 1. Preparar transparencia inicial del fondo gris y el texto "HAS MUERTO"
	fondo_muerte.modulate.a = 0.0
	label_muerte.modulate.a = 0.0
	fondo_muerte.visible = true
	label_muerte.visible = true
	
	var tween := create_tween()
	# Aparecen al mismo tiempo (parallel) en 0.6 segundos
	tween.set_parallel(true)
	tween.tween_property(fondo_muerte, "modulate:a", 1.0, 0.6)
	tween.tween_property(label_muerte, "modulate:a", 1.0, 0.6)
	
	# Volver a modo secuencial para esperar y fundir a negro
	tween.set_parallel(false)
	tween.tween_interval(2.5)
	tween.tween_property(fade_negro, "color:a", 1.0, 1.2)
	tween.tween_interval(0.3)
	tween.tween_callback(get_tree().reload_current_scene)
