extends Node

const bedtime = 21.00
var current_time = 23.14

func _ready() -> void:
	for node in get_children():
		if node.is_in_group("Enemies"):
			node.toggle_powers.connect($Player.toggle_using_powers)
		if node.is_in_group("Player"):
			var health_node = node.get_node("PlayerHealth")
			health_node.update_health.connect($UI.update_health_UI)
