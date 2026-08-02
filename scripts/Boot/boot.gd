extends Node

func _ready() -> void:
	
	if _already_saw_intro():
		SceneManager.goto_scene("res://scenes/Boot/main_menu.tscn")
	else:
		SceneManager.goto_scene("res://scenes/Boot/intro_cutscene.tscn")

func _already_saw_intro() -> bool:
	return FileAccess.file_exists("user://intro_seen.save")
