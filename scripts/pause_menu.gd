extends CanvasLayer

@onready var exit_button: Button = $ColorRect/ColorRect/ExitButton
@onready var resume_button: Button = $ColorRect/ColorRect/ResumeButton

func _ready() -> void:
	exit_button.pressed.connect(_exit)
	resume_button.pressed.connect(_resume)
	self.visible = false

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		toggle_pause_menu()

func _exit():
	get_tree().paused = not get_tree().paused
	SceneManager.goto_scene("res://scenes/Boot/main_menu.tscn")

func _resume():
	toggle_pause_menu()

func toggle_pause_menu():
	self.visible = !self.visible
	get_tree().paused = not get_tree().paused
	
