extends Node

const PLAYER_SCENE = preload("res://scenes/player.tscn")

@onready var player_spawn_point = $PlayerSpawnPoint

func _ready() -> void:
	_make_connections()
		
func _on_player_been_defeated() -> void:
	call_deferred("_spawn_player")

func _spawn_player():
	$Player.position = player_spawn_point.position

func _make_connections():
		for node in get_children():
			if node.is_in_group("Enemies"):
				node.toggle_powers.connect($Player.toggle_using_powers)
			if node.is_in_group("Player"):
				var health_node = node.get_node("PlayerHealth")
				health_node.update_health.connect($UI.update_health_UI)
