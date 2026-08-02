class_name Explosion
extends Node2D

@export var duration: float = 0.6 # Animation length in seconds

func _ready() -> void:
	# 1. Create a tween bound to this node's lifecycle
	var tween := create_tween()
	
	# 2. Animate the 'progress' shader parameter from 0.0 to 1.0
	tween.tween_property(
		material, 
		"shader_parameter/progress", 
		1.0, 
		duration
	).from(0.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# 3. Queue free automatically when the tween completes
	tween.tween_callback(queue_free)
