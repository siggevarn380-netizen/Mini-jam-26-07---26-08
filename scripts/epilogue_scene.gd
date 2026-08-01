extends Control

@export var scenes: Array[VNScene]

@onready var background: TextureRect = $BackGround
@onready var speaker_label: Label = $TextBox/SpeakerLabel
@onready var dialogue_text: RichTextLabel = $TextBox/TextLabel

var current_index: int = 0

func _ready() -> void:
	_show_scene(current_index)

func _show_scene(index: int) -> void:
	var scene_data := scenes[index]
	background.texture = scene_data.background
	dialogue_text.text = scene_data.text
	
	speaker_label.text = scene_data.speaker_name
	speaker_label.visible = scene_data.speaker_name != ""

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed or (event is InputEventKey and event.pressed):
		print("Continue")
		_advance()

func _advance() -> void:
	current_index += 1
	if current_index >= scenes.size():
		print("End")
		#SceneManager.goto_scene("res://credits.tscn")
	else:
		_show_scene(current_index)
