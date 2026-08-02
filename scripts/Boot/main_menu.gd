extends Control

@onready var exit_button: Button = $Pannel/ButtonPannel/ExitButton
@onready var start_button: Button = $Pannel/ButtonPannel/StartButton


func _ready() -> void:
	exit_button.pressed.connect(_on_exit_button_pressed)
	start_button.pressed.connect(_on_start_button_pressed)

func _on_start_button_pressed() -> void:
	$MenuMusic.stop()
	$StartSound.play()
	await get_tree().create_timer(2.2).timeout
	SceneManager.goto_scene("res://scenes/Boot/testscene.tscn")

func _on_exit_button_pressed() -> void:
	get_tree().quit()
