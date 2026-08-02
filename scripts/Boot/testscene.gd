extends Node2D

const BOSS_SCENE = preload("res://scenes/Enemy/boss.tscn")

@onready var player_spawn_point := $PlayerSpawnPoint
@onready var boss_spawn_point := $BossSpawnPoint

var player_lives: int = 3
var player_score: int = 0

func _ready() -> void:
    for node in get_children():
        if node.is_in_group("Player"):
            node.been_defeated.connect(self._respawn_player)
            node.victory.connect(self._player_victory)
            var health_node = node.get_node("PlayerHealth")
            health_node.update_health.connect($UI.update_health_UI)
        if node.is_in_group("Enemies"):
            node.was_destroyed.connect(self._update_score_UI)
    $UI.udpate_player_lives_UI(player_lives)
    _update_score_UI(0)
    
func _respawn_player():
    player_lives -= 1
    $UI.udpate_player_lives_UI(player_lives)
    if player_lives > 0:
        $Player.position = player_spawn_point.position
    else:
        SceneManager.goto_scene("res://scenes/Boot/game_over_menu.tscn")

func _update_score_UI(amount: int):
    player_score += amount
    $UI/ScoreUI/ScoreValues.text = str(player_score)

func _player_victory():
    SceneManager.goto_scene("res://scenes/Boot/epilogue_scene.tscn")

func _on_timer_timeout() -> void:
    var boss = BOSS_SCENE.instantiate()
    boss.position = boss_spawn_point.position
    get_tree().current_scene.add_child(boss)
    for spawner in $Spawners.get_children():
        spawner.set_process(false)
