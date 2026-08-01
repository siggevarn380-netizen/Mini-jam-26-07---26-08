extends Area2D

enum Type{WEAK, MID, STRONG}

@export var type: Type = Type.WEAK

const weak: float = 15.0
const mid: float = 30.0
const strong: float = 50.0

var potency: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	match type:
		Type.WEAK:
			potency = weak
		Type.MID:
			potency = mid
		Type.STRONG:
			potency = strong


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		body.add_potency(potency)
		self.queue_free()
