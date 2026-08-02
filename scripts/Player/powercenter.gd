extends Area2D

@export_group("Nodes")
@export var rShape: CollisionShape2D
@export var sprite: Node2D

@export_group("Field")
@export var radius: float = 15.0
@export var capture_ratio: float = 0.8      # capture reach vs repulse reach

@export_group("Hold")
@export var stiffness: float = 700.0
@export var damping_ratio: float = 0.3
@onready var damping: float = 2.0 * sqrt(stiffness) * damping_ratio

@export_group("Follow")
@export var follow_accel: float = 100.0
@export var follow_damp: float = 7.0
@export var max_follow_speed: float = 6000.0

@export_group("Repulse")
@export var restitution: float = 1.1
@export var min_bounce_speed: float = 400.0
@export var bounce_cooldown: float = 0.15

@export_group("Throw")
@export var min_throw_speed: float = 800.0
@export var throw_speed_mult: float = 1.0

var velocity: Vector2
var enabled := false
var mouse_pos: Vector2
var held: Array[Node2D] = []
var last_throw_dir: Vector2 = Vector2.RIGHT
var _cooldowns: Dictionary = {}


func _ready() -> void:
	rShape.shape = rShape.shape.duplicate()   # don't edit the shared resource
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	set_radius(radius)


func set_radius(r: float) -> void:
	radius = r
	rShape.shape.radius = r
	if sprite and sprite.texture:
		sprite.scale = Vector2.ONE * (r * 2.0 / sprite.texture.get_width())


func _physics_process(delta: float) -> void:
	for id in _cooldowns.keys():
		_cooldowns[id] -= delta
		if _cooldowns[id] <= 0.0:
			_cooldowns.erase(id)

	if not enabled:
		return

	var to_mouse := mouse_pos - global_position
	velocity += to_mouse * follow_accel * delta
	velocity *= exp(-follow_damp * delta)
	velocity = velocity.limit_length(max_follow_speed)
	global_position += velocity * delta

	if velocity.length() > 50.0:
		last_throw_dir = velocity.normalized()

	_hold(delta)


func _hold(delta: float) -> void:
	for i in range(held.size() - 1, -1, -1):
		var node := held[i]
		if not is_instance_valid(node):
			held.remove_at(i)
			continue
		if node is RigidBody2D:
			var offset := global_position - node.global_position
			node.apply_central_force((offset * stiffness - node.linear_velocity * damping) * node.mass)
		else:
			node.global_position = node.global_position.lerp(
				global_position, 1.0 - exp(-stiffness * 0.01 * delta))


func _apply_power(pos: Vector2) -> void:
	mouse_pos = pos
	if enabled:
		return
	global_position = pos
	velocity = Vector2.ZERO
	enabled = true
	sprite.visible = true
	_capture_at(pos)


func _capture_at(pos: Vector2) -> void:
	held.clear()
	var circle := CircleShape2D.new()
	circle.radius = radius * capture_ratio

	var params := PhysicsShapeQueryParameters2D.new()
	params.shape = circle
	params.transform = Transform2D(0.0, pos)
	params.collision_mask = collision_mask
	params.collide_with_bodies = true
	params.collide_with_areas = true
	params.exclude = [get_rid()]

	for hit in get_world_2d().direct_space_state.intersect_shape(params, 32):
		var node = hit.collider
		if not (node is Node2D):
			continue
		var grabbable = (node.is_in_group("Enemies") and not node.is_in_group("Boss")) \
			or node.is_in_group("Projectiles")
		if grabbable:
			held.append(node)
			if node.has_method("_on_dragged"):
				node._on_dragged()


func _disable_power() -> void:
	if enabled:
		_throw_all()
	enabled = false
	sprite.visible = false
	held.clear()
	velocity = Vector2.ZERO


func _throw_all() -> void:
	var speed: float = maxf(velocity.length() * throw_speed_mult, min_throw_speed)
	var throw_vel := last_throw_dir * speed
	for node in held:
		if not is_instance_valid(node):
			continue
		if node is RigidBody2D:
			node.linear_velocity = throw_vel
			if node.has_method("_on_released"):
				node._on_released()
		elif node.has_method("_on_released"):
			node._on_released(throw_vel)


func _on_body_entered(body: Node2D) -> void:
	if not enabled or body in held:
		return
	if not body.is_in_group("Enemies") or body.is_in_group("Boss"):
		return
	if not (body is RigidBody2D):
		return

	var id := body.get_instance_id()
	if _cooldowns.has(id):
		return
	_cooldowns[id] = bounce_cooldown

	var n := (body.global_position - global_position).normalized()
	if n == Vector2.ZERO:
		n = Vector2.RIGHT

	var rel = body.linear_velocity - velocity
	if rel.dot(n) < 0.0:
		rel = rel.bounce(n) * restitution
	var outward = rel.dot(n)
	if outward < min_bounce_speed:
		rel += n * (min_bounce_speed - outward)
	body.linear_velocity = rel + velocity


# Deflect bullets that fly into the field. Delete if you don't want it.
func _on_area_entered(area: Node2D) -> void:
	if not enabled or area in held:
		return
	if not area.is_in_group("Projectiles"):
		return
	var n := (area.global_position - global_position).normalized()
	if n == Vector2.ZERO:
		return
	if area.has_method("_on_released"):
		area._on_released(n * min_bounce_speed)
