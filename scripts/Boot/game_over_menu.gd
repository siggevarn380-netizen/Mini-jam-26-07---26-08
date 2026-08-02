extends Control

@onready var restart_button: Button = $Panel/RestartButton
@onready var exit_button: Button = $Panel/MenuButton

func _ready() -> void:
	restart_button.pressed.connect(_restart)
	exit_button.pressed.connect(_exit)

func _restart():
	SceneManager.goto_scene("res://scenes/Boot/testscene.tscn")

func _exit():
	SceneManager.goto_scene("res://scenes/Boot/main_menu.tscn")
