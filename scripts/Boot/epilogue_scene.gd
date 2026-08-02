extends Control

@export var scenes: Array[VNScene]

@onready var speaker_label: Label = $TextBox/SpeakerLabel
@onready var dialogue_text: Label = $TextBox/TextLabel
@onready var advance_button: Button = $TextBox/AdvanceButton

var current_index: int = 0

func _ready() -> void:
	_show_scene(current_index)
	advance_button.pressed.connect(_advance)

func _show_scene(index: int) -> void:
	var scene_data := scenes[index]
	dialogue_text.text = scene_data.text
	
	speaker_label.text = scene_data.speaker_name
	speaker_label.visible = scene_data.speaker_name != ""



func _advance() -> void:
	current_index += 1
	if current_index >= scenes.size():
		SceneManager.goto_scene("res://scenes/Boot/credits.tscn")
	else:
		_show_scene(current_index)
