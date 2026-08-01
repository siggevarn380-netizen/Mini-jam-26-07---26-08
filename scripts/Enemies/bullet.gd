extends Area2D

@export var speed: float = 500.0
@export var damage: int = 1

var direction: Vector2 = Vector2.RIGHT

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

func launch(dir: Vector2) -> void:
	direction = dir.normalized()
	rotation = direction.angle()

func _on_body_entered(body: Node) -> void:
	if !body.is_in_group("Enemies"):
		if body.is_in_group("Player") and !body.is_invulnerable:
			body.take_damage.emit(damage)
		queue_free()
