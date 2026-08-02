class_name Health extends Node2D

signal update_health(current_health: int, max_health: int)
signal death
signal got_hit

@export var starting_health: int = 10
@export var max_health: int = 10
@export var invulnerable_time : float = 2.0

var is_invulnerable = false
var invulnerable_timer = 0.0

var health: int

func _process(delta: float) -> void:
	is_invulnerable = invulnerable_timer > 0.0
	if is_invulnerable:
		invulnerable_timer = maxf(invulnerable_timer - delta, 0.0)


func _ready() -> void:
	await get_tree().process_frame
	health = 2
	update_health_bar()

func _on_player_take_damage(amount: int) -> void:
	health -= amount
	got_hit.emit()
	if health == 0:
		death.emit()
		health = max_health/2
	else: 
		invulnerable_timer = invulnerable_time
	update_health_bar()
	
func update_health_bar():
	update_health.emit(health, max_health)

func _on_player_gain_heart(amount: int) -> void:
	health += amount
	update_health_bar()
	print(health, " lives remaining.")
