extends Control

@onready var exit_button: Button = $TextureRect/ButtonPannel/ExitButton
@onready var start_button: Button = $TextureRect/ButtonPannel/StartButton

func _ready() -> void:
	exit_button.pressed.connect(_on_exit_button_pressed)
	start_button.pressed.connect(_on_start_button_pressed)

func _on_start_button_pressed() -> void:
	SceneManager.goto_scene("res://scenes/Boot/testscene.tscn")

func _on_exit_button_pressed() -> void:
	get_tree().quit()
