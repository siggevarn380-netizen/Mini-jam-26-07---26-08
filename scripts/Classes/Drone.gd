class_name Drone
extends RigidBody2D
signal take_damage()

enum State{SEEK, HOVER, DRAGGED, RELEASED, _NEXT}

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
@export var hover_freq: float = 1.0
@export var hover_arc: float = deg_to_rad(60.0)
@export var max_arc: float = deg_to_rad(70.0)
@export var max_hover_time: float = 5.0
@export var arrive_threshold: float = 20.0
@export_flags_2d_physics var enemy_layer_mask: int = 6
@export var roll_interval: float = 0.5
@export var max_seek_time: float = 3.0
@export var accel_gain: float = 8.0
@export var slow_radius: float = 200.0
@export_group("Rings")
@export var ring_count: int = 4
@export var ring_spacing: float = 70.0
@export var arc_jitter: float = 0.25      # ±25% sweep width variation
@export var dist_jitter: float = 0.15     # ±15% radius variation
@export var wobble_amp: float = deg_to_rad(8.0)
@export var wobble_freq: float = 3.7      # deliberately not a multiple of hover_freq
@export_group("Avoidance")
@export var sep_radius: float = 60.0
@export var separation_weight: float = 0.8   # fraction of `speed`, not a multiplier of it
@export var avoid_horizon: float = 1.2       # seconds of lookahead
@export var lateral_bias: float = 2.0        # sideways vs straight-back

var state = State.SEEK
var _last_velocity: Vector2 # Stash last speed before impact
var hover_dist: float = 0.0
var hover_time: float = 0.0
var hover_elapsed: float = 0.0
var seek_elapsed: float = 0.0
var roll_timer: float = 0.0
var hover_phase: float = 0.0
var my_arc: float = 0.0
var wobble_phase: float = 0.0

func _ready() -> void:
	set_physics_process(false)
	gravity_scale = 0.0
	hover_arc = minf(hover_arc, max_arc)
	linear_damp = 0.0
	sep_field.get_node("CollisionShape2D").shape.radius = sep_radius
	await get_tree().process_frame
	_enter_seek()
	set_physics_process(true)
func _physics_process(delta: float) -> void:
	match state:
		State.SEEK:
			if not is_instance_valid(target): return
			hover_time += delta
			var dest := target.global_position + Vector2.from_angle(_hover_angle()) * hover_dist
			_steer_to(dest)
			seek_elapsed += delta
			var at_radius := absf(global_position.distance_to(target.global_position) - hover_dist) < arrive_threshold
			if at_radius or seek_elapsed > max_seek_time:
				_enter_hover()
		State.HOVER:
			if not is_instance_valid(target): return
			hover_time += delta
			var dest := target.global_position + Vector2.from_angle(_hover_angle()) * hover_dist
			_steer_to(dest)
			hover_elapsed += delta
			roll_timer += delta
			var forced := hover_elapsed > max_hover_time
			var opportunity := false
			if roll_timer >= roll_interval:
				roll_timer = 0.0
				opportunity = _roll_for_action()
			if forced or opportunity:
				_on_hover_action()
		State.DRAGGED:
			pass
		State.RELEASED:
			if comp_timer.is_stopped(): _enter_seek()
			else:
				linear_velocity.y += 10

# --- hooks for subclasses ---
func _roll_for_action() -> bool:
	return false
func _on_hover_action() -> void:
	pass

func _enter_seek() -> void:
	state = State.SEEK
	if not is_instance_valid(target):
		target = get_tree().get_first_node_in_group("Player")
	if is_instance_valid(target):
		var flock := get_tree().get_nodes_in_group("Drones")
		var idx := flock.find(self)
		if idx < 0:
			push_warning("%s not in Drones group" % name)
			idx = 0
		var ring := idx % ring_count
		var in_ring := idx / ring_count
		#var per_ring := maxf(ceilf(float(flock.size()) / float(ring_count)), 1)
		hover_dist = (target.power_range * 1.1 + ring * ring_spacing) * (1.0 + randf_range(-dist_jitter, dist_jitter))
		my_arc = hover_arc * (1.0 + randf_range(-arc_jitter, arc_jitter))
		my_arc = minf(my_arc, max_arc)
		hover_phase = randf() * TAU
		wobble_phase = randf() * TAU
	hover_time = 0.0
	linear_damp = 0.0
	seek_elapsed = 0.0
func _enter_hover() -> void:
	state = State.HOVER
	hover_elapsed = 0.0
	roll_timer = 0.0

func _hover_angle() -> float:
	var t := fmod(hover_time * hover_freq + hover_phase, TAU) / TAU
	var tri := 4.0 * absf(t - 0.5) - 1.0
	var wobble := sin(hover_time * wobble_freq + wobble_phase) * wobble_amp
	return -PI / 2.0 + tri * my_arc + wobble

	
func _get_separation() -> Vector2:
	var push := Vector2.ZERO
	for other in sep_field.get_overlapping_bodies():
		if other == self or not other.is_in_group("Drones"): continue

		var to_other: Vector2 = other.global_position - global_position
		var d := to_other.length()
		if d < 0.001:
			push += Vector2.from_angle(float(get_instance_id() % 628) * 0.01)
			continue

		var p := to_other / d
		var rel: Vector2 = linear_velocity - other.linear_velocity
		var closing := rel.dot(p)

		# mild personal space, always on
		var prox := maxf(0.0, 1.0 - d / sep_radius)
		push += -p * prox * 0.4

		if closing <= 1.0: continue        # already separating — let them through
		var ttc := d / closing
		if ttc > avoid_horizon: continue

		# the part of our relative motion that isn't straight at them
		var lateral := rel - p * closing
		if lateral.length_squared() < 1.0:
			# dead-on: both compute the same parity, so the tangents come out opposite
			var parity := (get_instance_id() ^ other.get_instance_id()) & 1
			lateral = p.orthogonal() * (1.0 if parity == 0 else -1.0)

		push += (lateral.normalized() * lateral_bias - p) * (1.0 - ttc / avoid_horizon)
	return push.limit_length(1.0)

func _steer_to(dest: Vector2) -> void:
	var sep := _get_separation()
	var to_dest := dest - global_position
	var dist := to_dest.length()
	var desired := Vector2.ZERO
	if dist > 0.001:
		var seek_scale := 1.0 - minf(sep.length(), 1.0) * 0.5
		desired = (to_dest / dist) * speed * minf(dist / slow_radius, 1.0) * seek_scale
	desired += sep * speed * separation_weight
	desired = desired.limit_length(speed)
	apply_central_force((desired - linear_velocity) * mass * accel_gain)
	
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
	if body.is_in_group("Player"):
		if !body.get_node("PlayerHealth").is_invulnerable:
			body.take_damage.emit(1)
		take_damage.emit()
	if body.is_in_group("Enemies"):
		if closing_speed > body.impact_tolerance:
			body.take_damage.emit()
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
