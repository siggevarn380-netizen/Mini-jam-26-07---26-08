extends Area2D

enum State{NORMAL, DRAGGED, RELEASED}


@export var speed: float = 500.0
@export var damage: int = 1

var state = State.NORMAL
var last_pos: Vector2

var direction: Vector2 = Vector2.RIGHT

func _physics_process(delta: float) -> void:
	if state == State.DRAGGED:
		last_pos = global_position
	else:
		position += direction * speed * delta
func launch(dir: Vector2) -> void:
	direction = dir.normalized()
	rotation = direction.angle()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Power"): return
	if body.is_in_group("Enemies") and state != State.RELEASED: return
	if _can_damage(body):
		body.take_damage.emit(damage)
	queue_free()

func _can_damage(body: Node2D) -> bool:
	if body.is_in_group("Player") and !body.get_node("PlayerHealth").is_invulnerable:
		return true
	if body.is_in_group("Enemies"):
		if state == State.RELEASED:
			return true
	return false

func _on_dragged() -> void:
	state = State.DRAGGED
func _on_released() -> void:
	state = State.RELEASED
	var drag_dir = global_position - last_pos
	launch(drag_dir if drag_dir.length() > 0.01 else direction)
