extends Control

@onready var base: TextureRect = $Base
@onready var palanca: TextureRect = $Palanca

var touch_index: int = -1
var radio: float = 0.0
var centro_base: Vector2 = Vector2.ZERO

func _ready():
	centro_base = base.position + (base.size / 2.0)
	radio = base.size.x / 2.0
	reset_joystick()
	
func _gui_input(event: InputEvent):
	if event is InputEventScreenTouch:
		if event.pressed and touch_index == -1:
			var distancia_toque = event.position.distance_squared_to(centro_base)
			if distancia_toque <= radio:
				touch_index = event.index
				actualizar_joystick(event.position)
		elif not event.pressed and event.index == touch_index:
			touch_index = -1
			reset_joystick()
	elif event is InputEventScreenDrag and event.index == touch_index:
		actualizar_joystick(event.position)

func actualizar_joystick(pos_toque: Vector2):
	var vector = pos_toque - centro_base
	
	if vector.length() > radio:
		vector = vector.normalized() * radio
	
	palanca.position = centro_base + vector - (palanca.size / 2.0)
	
	var input_vector = vector / radio
	
	Input.action_press("right", input_vector.x if input_vector.x > 0 else 0)
	Input.action_press("left", -input_vector.x if input_vector.x < 0 else 0)
	Input.action_press("down", input_vector.y if input_vector.y > 0 else 0)
	Input.action_press("up", -input_vector.y if input_vector.y < 0 else 0)
	
func reset_joystick():
	palanca.position = centro_base - (palanca.size / 2.0)
	Input.action_release("right")
	Input.action_release("left")
	Input.action_release("down")
	Input.action_release("up")
