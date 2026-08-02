extends Control

@onready var video: VideoStreamPlayer = $VideoStreamPlayer
@onready var audio: AudioStreamPlayer2D	= $AudioStreamPlayer2D

var track_1 = preload("res://SFX/Music/OnATinyPlanet.ogg")
var track_2 = preload("res://SFX/Music/DroneArrival.ogg")

func _ready() -> void:
	video.finished.connect(_on_video_finished)
	
	audio.stream = track_1
	await get_tree().create_timer(5.13).timeout
	audio.play()
	await get_tree().create_timer(22.18).timeout
	audio.stop()
	
	audio.stream = track_2
	
	audio.play()
	
func _on_video_finished() -> void:
	SceneManager.goto_scene("res://scenes/Boot/main_menu.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey or event is InputEventMouseButton:
		if event.pressed:
			_on_video_finished()
