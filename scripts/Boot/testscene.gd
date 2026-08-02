extends Node2D

@onready var player_spawn_point := $PlayerSpawnPoint

var player_lives: int = 3

func _ready() -> void:
	for node in get_children():
		if node.is_in_group("Player"):
			node.been_defeated.connect(self._respawn_player)
			var health_node = node.get_node("PlayerHealth")
			health_node.update_health.connect($UI.update_health_UI)
	$UI.update_lives_UI(player_lives)

func _respawn_player():
	player_lives -= 1
	if player_lives > 0:
		$Player.position = player_spawn_point.position
		$UI.update_lives_UI(player_lives)
	else:
		SceneManager.goto_scene("res://scenes/Boot/game_over_menu.tscn")
	
