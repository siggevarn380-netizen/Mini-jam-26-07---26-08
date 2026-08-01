class_name Health extends Node2D

signal update_health(current_health: int, max_health: int)
signal death
signal got_hit

@export var starting_health: int = 1
@export var max_health: int = 10

@onready var health: int = starting_health:
	set(modify_health):
		health = clampi(modify_health, 0, max_health)

func _ready() -> void:
	await get_tree().process_frame
	update_health_bar()

func _on_player_take_damage(amount: int) -> void:
	health -= amount
	update_health_bar()
	got_hit.emit()
	if health == 0:
		death.emit()
		print("Pow dead")
	else: print(health, " lives remaining.")
	

func _on_health_add(amount: int):
	health += amount
	update_health_bar()
	print(health, " lives remaining.")

func update_health_bar():
	update_health.emit(health, max_health)

func _on_player_been_defeated() -> void:
	health = 5
