extends Node2D

signal died
signal health_changed(current: int, maximum: int)

@export var max_health: int = 3
var health: int

@export var invulnerable_time : float = 2.0
var is_invulnerable = false
var invulnerable_timer = 0.0

func _ready() -> void:
	health = max_health
	print(health)

func _process(delta: float) -> void:
	is_invulnerable = invulnerable_timer > 0.0
	if is_invulnerable:
		invulnerable_timer = maxf(invulnerable_timer - delta, 0.0)

func _on_boss_take_damage(amount: int) -> void:
	print("boss recibió daño: ", amount, " salud antes: ", health, " invuln: ", invulnerable_timer)
	if health <= 0: return
	if invulnerable_timer > 0.0: return
	health -= amount
	health_changed.emit(health, max_health)
	if health <= 0:
		died.emit()
	else:
		invulnerable_timer = invulnerable_time
		is_invulnerable = true
