extends Control

@onready var exit_button: Button = $TextureRect/Panel/ExitButton
@onready var back_button: Button = $TextureRect/Panel/BackButton

func _ready() -> void:
	exit_button.pressed.connect(_exit)
	back_button.pressed.connect(_back_to_menu)

func _exit():
	get_tree().quit()

func _back_to_menu():
	SceneManager.goto_scene("res://scenes/Boot/main_menu.tscn")
