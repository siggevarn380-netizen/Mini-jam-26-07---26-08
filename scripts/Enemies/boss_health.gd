extends Node2D

signal died
signal health_changed(current: int, maximum: int)

@export var max_health: int = 30
var health: int

func _ready() -> void:
	health = max_health
	
func _on_boss_take_damage(amount: Variant) -> void:
	if health <= 0: return
	health -= amount
	health_changed.emit(health, max_health)
	if health <= 0:
		died.emit()
