extends RigidBody2D
signal take_damage()
signal toggle_powers

enum State{SEEK, HOVER, CHARGE, DRAGGED, RELEASED}

const REST_ROTATION: float = 0.0

@export_group("Nodes")
@export var sep_field: Area2D
@export_group("General")
@export var impact_tolerance : float = 500 #The speed required for a drone to explode when impacting terrain or walls
@export var comp_timer: Timer
@export var speed: float = 700
@export var right_stiffness: float = 8.0
@export var max_right_speed: float = 3.0
@onready var target: Node2D = get_tree().get_first_node_in_group("Player")
@export var max_hover_dist: float = 2000.0
@export var hover_freq: float = 2.0
@export var hover_arc: float = PI / 8
@export var max_hover_time: float = 5.0
@export var arrive_threshold: float = 20.0
@export var separation_weight: float = 3.0
@export_flags_2d_physics var enemy_layer_mask: int = 6
@export var roll_interval: float = 0.5
@export var charge_accel: float = 500
@export var sep_radius: float = 30
@export var max_seek_time: float = 3.0
@export var angle_spread: float = PI / 2
@export var ring_count: int = 4
@export var ring_spacing: float = 30.0

var state = State.SEEK
var _last_velocity: Vector2 # Stash last speed before impact
var hover_dist: float = 0.0
var hover_time: float = 0.0
var hover_elapsed: float = 0.0
var seek_elapsed: float = 0.0
var roll_timer: float = 0.0
var charge_target: Vector2
var angle_offset: float = 0.0

func _ready() -> void:
	_enter_seek()
	sep_field.get_node("CollisionShape2D").shape.radius = sep_radius
func _physics_process(delta: float) -> void:
	match state:
		State.SEEK:
			if not is_instance_valid(target): return
			var dest := target.global_position + Vector2.from_angle(-PI / 2 + angle_offset) * hover_dist
			_steer_to(dest)
			seek_elapsed += delta
			var at_radius = absf(global_position.distance_to(target.global_position) - hover_dist) < arrive_threshold
			if at_radius or seek_elapsed > max_seek_time:
				_enter_hover()
		State.HOVER:
			if not is_instance_valid(target): return
			hover_time += delta
			var angle = -PI / 2 + angle_offset + sin(hover_time * hover_freq) * hover_arc
			var dest = target.global_position + Vector2.from_angle(angle) * hover_dist
			_steer_to(dest)
			hover_elapsed += delta
			roll_timer += delta
			var forced: = hover_elapsed > max_hover_time
			var opportunity = false
			if roll_timer >= roll_interval:
				roll_timer = 0.0
				if _path_is_clear():
					var ratio := clampf(absf(target.velocity.x) / target.max_speed, 0.0, 1.0)
					var chance := pow(1.0 - ratio, 2.0)
					opportunity = randf() < chance
			if forced or opportunity:
				_enter_charge()
				
		State.CHARGE:
			var dir := (charge_target - global_position).normalized()
			apply_central_force(dir * charge_accel * mass)
		State.DRAGGED:
			pass
		State.RELEASED:
			if comp_timer.is_stopped(): _enter_seek()
			else:
				linear_velocity.y += 10
				
func _enter_seek() -> void:
	state = State.SEEK
	if not is_instance_valid(target):
		target = get_tree().get_first_node_in_group("Player")
	if is_instance_valid(target):
		var ring = randi() % ring_count
		hover_dist = target.power_range * 1.1 + ring * ring_spacing
	hover_time = randf() * TAU
	angle_offset = randf_range(-angle_spread, angle_spread)
	seek_elapsed = 0.0
func _enter_hover() -> void:
	state = State.HOVER
	hover_elapsed = 0.0
	roll_timer = 0.0
func _enter_charge() -> void:
	state = State.CHARGE
	charge_target = target.global_position
	linear_damp = 0.0
	
func _get_separation() -> Vector2:
	var push = Vector2.ZERO
	for other in sep_field.get_overlapping_bodies():
		if other == self: continue
		var away = global_position - other.global_position
		var d = away.length()
		if d > 0.0:
			var w = maxf(0.0, 1.0 - d / sep_radius)
			push += away.normalized() * w
	return push.limit_length(1.0)

func _steer_to(dest):
	var sep = _get_separation()
	var seek_scale = 1.0 - minf(sep.length(), 1.0) * 0.4
	var desired = (dest - global_position).normalized() * speed * seek_scale
	desired += sep * separation_weight * speed
	var steering = desired - linear_velocity
	apply_central_force(steering * mass)
	
func _path_is_clear() -> bool:
	if not is_instance_valid(target): return false
	var space = get_world_2d().direct_space_state
	var q = PhysicsRayQueryParameters2D.create(
		global_position, target.global_position, enemy_layer_mask, [self]
	)
	return space.intersect_ray(q).is_empty()
func _integrate_forces(body_state: PhysicsDirectBodyState2D) -> void:
	_last_velocity = body_state.linear_velocity
	if state == State.HOVER:
		var err := angle_difference(rotation, REST_ROTATION)
		body_state.angular_velocity = clampf(err * right_stiffness, -max_right_speed, max_right_speed)

func _on_body_entered(body: Node) -> void:
	var to_body = (body.global_position - global_position).normalized()
	var closing_speed = _last_velocity.dot(to_body)
	if closing_speed > impact_tolerance:
		if body.is_in_group("Player"):
			if !body.get_node("PlayerHealth").is_invulnerable:
				body.take_damage.emit(1)
		if body.is_in_group("Enemies"):
			body.take_damage.emit(1)
		take_damage.emit()

func _on_dragged() -> void:
	state = State.DRAGGED
func _on_released()     -> void:
	comp_timer.start()
	state = State.RELEASED


	
func destroy():
	set_deferred("freeze", true)
	$CollisionShape2D.set_deferred("disabled", true)
	hide()
	set_deferred("process_mode", PROCESS_MODE_DISABLED)

func _on_take_damage() -> void:
	destroy()
