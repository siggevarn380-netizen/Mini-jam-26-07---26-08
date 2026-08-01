extends Area2D

@export_group("Nodes")
@export var rShape: CollisionShape2D
@export var sprite: Node2D
@export_group("General")
@export var start_size: float = 1.0
@export var start_max: float = 15.0
@export var strength: float = 40000
@export var base_follow: float = 600
@export var stiffness: float = 300.0
@onready var dampening: float = 2.0 * sqrt(stiffness)
@export var growth_rate: float = 10.0
var max_reach = start_max
var enabled = false
var moving = false
var mouse_pos: Vector2
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	rShape.shape.radius = start_size
	body_exited.connect(_on_body_exited)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	rShape.shape.radius = clampf(rShape.shape.radius + r_rate() * delta, 0.0, max_reach)
	var follow = base_follow if moving else base_follow * 2
	if enabled:
		global_position = global_position.move_toward(mouse_pos, follow * delta)
	for body in get_overlapping_bodies():
		if body.is_in_group("Enemies") and enabled:
			var offset = global_position - body.global_position
			body.apply_central_force((offset * stiffness - body.linear_velocity * dampening) * body.mass)
			body._on_dragged()

func r_rate() -> float:
	if enabled and !moving: return growth_rate
	if enabled: return -5.0
	return -10.0

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("Enemies"):
		body._on_released()
	
func _apply_power(pos: Vector2) -> void:
	mouse_pos = pos
	if !enabled: global_position = mouse_pos
	enabled = true
	sprite.visible = true

func _disable_power() -> void:
	enabled = false
	sprite.visible = false
	
