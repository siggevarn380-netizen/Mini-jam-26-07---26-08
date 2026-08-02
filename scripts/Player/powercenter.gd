extends Area2D

enum Mode{REPULSOR, CAPTURE}

@export_group("Nodes")
@export var rShape: CollisionShape2D
@export var sprite: Node2D
@export_group("General")
@export var start_size: float = 1.0
@export var start_max: float = 15.0
@export var strength: float = 40000
@export var base_follow: float = 600
@export var stiffness: float = 700
@export var damping_ratio = 0.3
@onready var damping: float = 2.0 * sqrt(stiffness) * damping_ratio
@export var growth_rate: float = 20.0
@export_group("Follow")
@export var follow_accel: float = 100.0    # spring pull toward mouse
@export var follow_damp: float = 7.0     # lower = more whip/overshoot
@export var max_follow_speed: float = 6000.0

var velocity: Vector2
var enabled = false
var moving = false
var mouse_pos: Vector2
var max_size: float
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	rShape.shape.radius = start_size
	body_exited.connect(_on_body_exited)
	area_exited.connect(_on_area_exited)
	max_size = start_max

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	rShape.shape.radius = clampf(rShape.shape.radius + r_rate() * delta, 0.0, max_size)
	#var follow = base_follow if moving else base_follow * 2
	if enabled:
		var to_mouse = mouse_pos - global_position
		velocity += to_mouse * follow_accel * delta
		velocity *= exp(-follow_damp * delta)
		velocity = velocity.limit_length(max_follow_speed)
		global_position += velocity * delta
		var diameter = rShape.shape.radius * 2.0
		sprite.scale = Vector2.ONE * (diameter / sprite.texture.get_width())
	for body in get_overlapping_bodies():
		if body.is_in_group("Enemies") and not body.is_in_group("Boss") and enabled:
			var offset = global_position - body.global_position
			body.apply_central_force((offset * stiffness - body.linear_velocity * damping) * body.mass)
			body._on_dragged()
	for area in get_overlapping_areas():
		if area.is_in_group("Projectiles") and enabled:
			area._on_dragged()
			area.global_position = area.global_position.lerp(global_position, 1.0 - exp(-stiffness * 0.01 * delta))

func r_rate() -> float:
	if enabled and !moving: return growth_rate
	if enabled: return 0.0
	return -growth_rate

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("Enemies") and not body.is_in_group("Boss"):
		body._on_released()
func _on_area_exited(area: Node2D) -> void:
	if area.is_in_group("Projectiles"):
		area._on_released()
func _apply_power(pos: Vector2) -> void:
	mouse_pos = pos
	if !enabled: global_position = mouse_pos
	enabled = true
	sprite.visible = true

func _disable_power() -> void:
	enabled = false
	sprite.visible = false
	
