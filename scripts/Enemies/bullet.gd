extends Area2D

enum State { NORMAL, DRAGGED, RELEASED }

@export var speed: float = 500.0
@export var damage: int = 1

var state := State.NORMAL
var direction: Vector2 = Vector2.RIGHT


func _physics_process(delta: float) -> void:
	if state == State.DRAGGED:
		return
	position += direction * speed * delta


func launch(dir: Vector2) -> void:
	direction = dir.normalized()
	rotation = direction.angle()


func _on_dragged() -> void:
	state = State.DRAGGED


func _on_released(launch_velocity: Vector2 = Vector2.ZERO) -> void:
	state = State.RELEASED
	if launch_velocity.length() > 1.0:
		launch(launch_velocity)
		speed = maxf(speed, launch_velocity.length())


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Power"):
		return
	if body.is_in_group("Enemies") and state != State.RELEASED:
		return
	if _can_damage(body):
		body.take_damage.emit(damage)
	queue_free()


func _can_damage(body: Node2D) -> bool:
	if body.is_in_group("Player") and !body.get_node("PlayerHealth").is_invulnerable:
		return true
	if body.is_in_group("Enemies"):
		return state == State.RELEASED
	return false
