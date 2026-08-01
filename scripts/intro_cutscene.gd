extends Control

@onready var video: VideoStreamPlayer = $VideoStreamPlayer

func _ready() -> void:
	video.finished.connect(_on_video_finished)

func _on_video_finished() -> void:
	SceneManager.goto_scene("res://scenes/Boot/main_menu.tscn")

func _unhandled_input(event: InputEvent) -> void:
	# Permitir skip con cualquier tecla/click
	if event is InputEventKey or event is InputEventMouseButton:
		if event.pressed:
			_on_video_finished()
