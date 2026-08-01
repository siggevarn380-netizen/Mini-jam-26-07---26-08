class_name PlayerHealth extends Node2D

signal death

@export var starting_health: int = 1
@export var max_health: int = 10

@onready var health: int = starting_health:
	set(modify_health):
		health = clampf(modify_health, 0, max_health)



func _on_player_take_damage(amount: int) -> void:
	health -= amount
	if health == 0:
		death.emit()
		print("Pow dead")
	else: print(health, " lives remaining.")

func _on_health_add(amount: int):
	health += amount
	print(health, " lives remaining.")
