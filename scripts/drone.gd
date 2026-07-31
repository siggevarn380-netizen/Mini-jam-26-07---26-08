extends RigidBody2D

var dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO

signal toggle_powers()

# Para calcular velocidad al soltar (efecto "tirar/lanzar")
var last_mouse_position: Array[Vector2] = []
const VELOCITY_SAMPLES = 5

func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed and not dragging:
			begin_dragging()

func _unhandled_input(event: InputEvent) -> void:
	if dragging and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			finish_draggin()

func begin_dragging() -> void:
	dragging = true
	freeze = true # desactiva la física mientras lo arrastrás
	drag_offset = global_position - get_global_mouse_position()
	last_mouse_position.clear()
	toggle_powers.emit()

func finish_draggin() -> void:
	dragging = false
	freeze = false # reactiva la física -> vuelve a caer
	toggle_powers.emit()

	# Calculamos velocidad promedio de los últimos frames para simular el "lanzamiento"
	if last_mouse_position.size() >= 2:
		var vel: Vector2 = (last_mouse_position[-1] - last_mouse_position[0]) / (last_mouse_position.size() * get_physics_process_delta_time())
		linear_velocity = vel
	else:
		linear_velocity = Vector2.ZERO

func _physics_process(_delta: float) -> void:
	if dragging:
		global_position = get_global_mouse_position() + drag_offset

		last_mouse_position.append(get_global_mouse_position())
		if last_mouse_position.size() > VELOCITY_SAMPLES:
			last_mouse_position.pop_front()

func _on_body_entered(_body: Node) -> void:
	destroy()
	
func destroy():
	set_deferred("freeze", true)
	$CollisionShape2D.set_deferred("disabled", true)
	hide()
	set_deferred("process_mode", PROCESS_MODE_DISABLED) 
