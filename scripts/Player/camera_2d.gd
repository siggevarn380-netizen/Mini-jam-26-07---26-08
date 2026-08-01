extends Camera2D

@export var target: Node2D

var locked_y: float

func _ready() -> void:
	locked_y = target.global_position.y
	global_position = Vector2(target.global_position.x, locked_y)

func _physics_process(_delta: float) -> void:
	global_position.x = target.global_position.x
