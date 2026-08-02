class_name Drone
extends RigidBody2D

# Base flocking drone.
#
# Lifecycle: SEEK (fly to formation slot) -> HOVER (hold slot, roll for an attack).
# DRAGGED / RELEASED are driven from outside by the player's grab power.
#
# Subclasses add attacks by overriding _roll_for_action() and _on_hover_action(),
# and may define extra states starting at State._NEXT.

signal take_damage(amount)

enum State {SEEK, HOVER, DRAGGED, RELEASED, _NEXT}

const REST_ROTATION: float = 0.0


# ---------------------------------------------------------------- Exports

@export_group("Nodes")
@export var sep_field: Area2D           # Detects nearby drones for separation
@export var comp_timer: Timer           # Recovery delay after being released

@export_group("Movement")
@export var speed: float = 700          # Cap on steering speed
@export var accel_gain: float = 8.0     # How hard we correct toward desired velocity
@export var slow_radius: float = 200.0  # Ease off within this distance of the slot
@export var right_stiffness: float = 8.0    # Rotation spring toward REST_ROTATION
@export var max_right_speed: float = 3.0    # Cap on that rotation, rad/s

@export_group("Formation")
@export var ring_count: int = 4         # Drones are spread across this many rings
@export var ring_spacing: float = 70.0  # Extra radius per ring outward
@export var dist_bias: float = 0.0      # Per-subclass push outward, in pixels
@export var dist_jitter: float = 0.15   # +/-15% radius variation
@export var arc_jitter: float = 0.25    # +/-25% sweep width variation

@export_group("Hover")
@export var hover_freq: float = 1.0             # Sweeps per second
@export var hover_arc: float = deg_to_rad(60.0) # Half-width of the sweep
@export var max_arc: float = deg_to_rad(70.0)   # Hard cap after jitter
@export var wobble_amp: float = deg_to_rad(8.0)
@export var wobble_freq: float = 3.7            # Deliberately not a multiple of hover_freq
@export var arrive_threshold: float = 20.0      # Radius tolerance for "arrived"
@export var max_seek_time: float = 3.0          # Give up seeking after this long
@export var max_hover_time: float = 5.0         # Force an action after this long
@export var roll_interval: float = 0.5          # Seconds between action rolls

@export_group("Boss Orbit")
@export var orbit_speed: float = 1.0            # rad/s around the boss
@export var orbit_hover_time: float = 900.0     # Replaces max_hover_time while orbiting
@export var max_simultaneous_charges: int = 2   # Read by attacking subclasses
@export var orbit_radius: float = 160.0   # Base ring radius when circling the boss
@export var swarm_spread: float = 60.0   # Random radius scatter, pixels
@export var swarm_clump: float = 0.35    # 1.0 = evenly spaced, 0.0 = all on one point
@export var orbit_ring_spacing: float = 0.0   # Extra radius per ring while orbiting

@export_group("Avoidance")
@export var sep_radius: float = 60.0
@export var separation_weight: float = 0.8   # Fraction of `speed`, not a multiplier of it
@export var avoid_horizon: float = 1.2       # Seconds of lookahead
@export var lateral_bias: float = 2.0        # Sideways vs straight-back

@export_group("Impact")
@export var impact_tolerance: float = 500       # Closing speed that destroys this drone
@export var knockback_multiplier: float = 1.2   # Bounce gain on collision
@export_flags_2d_physics var enemy_layer_mask: int = 6   # Layers that block line of sight

@export_group("Unused")
@export var max_hover_dist: float = 2000.0   # Kept for compatibility, never read


# ---------------------------------------------------------------- Runtime

@onready var target: Node2D = get_tree().get_first_node_in_group("Player")

var state = State.SEEK
var orbit_boss: Node2D = null       # When set, the flock circles this instead of the player
var incapacitated = false           # True while grabbed; suppresses the retreat reset

var _last_velocity: Vector2         # Pre-solver velocity, for impact math
var hover_dist: float = 0.0         # This drone's ring radius
var hover_phase: float = 0.0        # Position along the sweep / orbit
var wobble_phase: float = 0.0
var my_arc: float = 0.0             # This drone's jittered sweep width
var hover_time: float = 0.0         # Drives the sweep; never resets mid-formation
var hover_elapsed: float = 0.0      # Time in HOVER, for the forced action
var seek_elapsed: float = 0.0       # Time in SEEK, for the give-up timer
var roll_timer: float = 0.0


func _ready() -> void:
	set_physics_process(false)
	gravity_scale = 0.0
	hover_arc = minf(hover_arc, max_arc)
	linear_damp = 0.0
	sep_field.get_node("CollisionShape2D").shape.radius = sep_radius
	hover_phase = randf() * TAU
	await get_tree().process_frame   # Let the Drones group finish populating
	_enter_seek()
	set_physics_process(true)


func _physics_process(delta: float) -> void:
	# Adopt or release the boss the moment one appears or dies.
	if state != State.DRAGGED and state != State.RELEASED:
		var boss = get_tree().get_first_node_in_group("Boss")
		if boss != orbit_boss and boss != self:
			orbit_boss = boss
			_enter_seek()
			
	match state:
		State.SEEK:
			var anchor := _anchor()
			if not is_instance_valid(anchor): return
			hover_time += delta
			_steer_to(anchor.global_position + Vector2.from_angle(_hover_angle()) * hover_dist)
			seek_elapsed += delta
			var at_radius := absf(global_position.distance_to(anchor.global_position) - hover_dist) < arrive_threshold
			if at_radius or seek_elapsed > max_seek_time:
				_enter_hover()

		State.HOVER:
			var anchor := _anchor()
			if not is_instance_valid(anchor): return
			hover_time += delta
			_steer_to(anchor.global_position + Vector2.from_angle(_hover_angle()) * hover_dist)
			hover_elapsed += delta
			roll_timer += delta

			# Orbiting drones effectively never force an attack; they wait for a roll.
			var hover_limit := orbit_hover_time if anchor == orbit_boss else max_hover_time
			var forced := hover_elapsed > hover_limit

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
				linear_velocity.y += 10   # Sag while tumbling


# ------------------------------------------------- Hooks for subclasses

func _roll_for_action() -> bool:
	return false


func _on_hover_action() -> void:
	pass


# --------------------------------------------------------- State entry

func _enter_seek() -> void:
	incapacitated = false
	state = State.SEEK
	var found = get_tree().get_first_node_in_group("Boss")
	orbit_boss = found if found != self else null
	if is_instance_valid(orbit_boss) and orbit_boss.has_method("apply_flock_settings"):
		orbit_boss.apply_flock_settings(self)
	if not is_instance_valid(target):
		target = get_tree().get_first_node_in_group("Player")

	if is_instance_valid(target):
		# Ring assignment comes from position in the Drones group, so the
		# flock spreads across rings without any central coordinator.
		var flock := get_tree().get_nodes_in_group("Drones")
		var idx := flock.find(self)
		if idx < 0:
			push_warning("%s not in Drones group" % name)
			idx = 0
		var ring := idx % ring_count

		if _anchor() == orbit_boss:
			hover_dist = (orbit_radius + randf_range(-swarm_spread, swarm_spread))
			hover_phase = TAU * float(idx) / float(maxi(flock.size(), 1)) * swarm_clump + randf_range(-0.3, 0.3)
		else:
			hover_dist = (target.power_range * 1.5 + ring * ring_spacing + dist_bias) * (1.0 + randf_range(-dist_jitter, dist_jitter))
			hover_phase = randf() * TAU
		my_arc = hover_arc * (1.0 + randf_range(-arc_jitter, arc_jitter))
		my_arc = minf(my_arc, max_arc)
		wobble_phase = randf() * TAU

	hover_time = 0.0
	linear_damp = 0.0
	seek_elapsed = 0.0


func _enter_hover() -> void:
	state = State.HOVER
	hover_elapsed = 0.0
	roll_timer = 0.0


# ------------------------------------------------------------ Formation

## What the flock arranges itself around: the boss if one is set, else the player.
func _anchor() -> Node2D:
	return orbit_boss if is_instance_valid(orbit_boss) else target


## Angle of this drone's slot around the anchor.
## Orbiting: monotonic sweep, full circle. Otherwise: triangle wave above the player.
func _hover_angle() -> float:
	if is_instance_valid(orbit_boss):
		# Global clock: re-entering SEEK can't teleport us around the ring.
		return hover_phase + (Time.get_ticks_msec() / 1000.0) * orbit_speed
	var t := fmod(hover_time * hover_freq + hover_phase, TAU) / TAU
	var tri := 4.0 * absf(t - 0.5) - 1.0
	var wobble := sin(hover_time * wobble_freq + wobble_phase) * wobble_amp
	return -PI / 2.0 + tri * my_arc + wobble
	


# ------------------------------------------------------------- Steering

## Unit-length push away from crowding neighbours, blending gentle personal
## space with predictive avoidance of drones we're about to collide with.
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


## Arrive-style steering toward a point, with separation folded in.
func _steer_to(dest: Vector2) -> void:
	var sep := _get_separation()
	var to_dest := dest - global_position
	var dist := to_dest.length()
	var desired := Vector2.ZERO
	if dist > 0.001:
		# Crowded drones commit less to the slot and more to getting clear.
		var seek_scale := 1.0 - minf(sep.length(), 1.0) * 0.5
		desired = (to_dest / dist) * speed * minf(dist / slow_radius, 1.0) * seek_scale
	desired += sep * speed * separation_weight
	desired = desired.limit_length(speed)
	apply_central_force((desired - linear_velocity) * mass * accel_gain)


## True when nothing on enemy_layer_mask sits between us and the player.
func _path_is_clear() -> bool:
	if not is_instance_valid(target): return false
	var space = get_world_2d().direct_space_state
	var q = PhysicsRayQueryParameters2D.create(
		global_position, target.global_position, enemy_layer_mask, [self]
	)
	return space.intersect_ray(q).is_empty()


func _integrate_forces(body_state: PhysicsDirectBodyState2D) -> void:
	_last_velocity = body_state.linear_velocity   # Pre-solver, so impacts read true speed
	if state == State.HOVER:
		var err := angle_difference(rotation, REST_ROTATION)
		body_state.angular_velocity = clampf(err * right_stiffness, -max_right_speed, max_right_speed)


# --------------------------------------------------------------- Impact

func _on_body_entered(body: Node) -> void:
	# Both bodies run this independently and see the same relative closing
	# speed, so each destroys itself rather than reaching across.
	var rel = _last_velocity - _velocity_of(body)
	var to_body: Vector2
	if body.is_in_group("Static"):
		to_body = _last_velocity.normalized()
	else:
		to_body = (body.global_position - global_position).normalized()
	var closing_speed = rel.dot(to_body)

	if body.is_in_group("Player"):
		if !body.get_node("PlayerHealth").is_invulnerable:
			if self.is_in_group("Explosive") or closing_speed > impact_tolerance:
				body.take_damage.emit(1)

	if closing_speed > impact_tolerance:
		take_damage.emit(1)
			

	if _should_retreat(body, closing_speed):
		_enter_seek()

	var kick = maxf(closing_speed, 0.0) * knockback_multiplier
	apply_central_impulse(-to_body * kick * mass)


## Velocity of whatever we hit. Only drones and the player actually move.
func _velocity_of(body: Node) -> Vector2:
	if body.is_in_group("Player"): return body.velocity
	if body.is_in_group("Drones"): return body._last_velocity
	return Vector2.ZERO


## Light scrapes against level geometry shouldn't break whatever we were doing.
func _should_retreat(body: Node2D, closing_speed: float) -> bool:
	if incapacitated: return false
	if body.is_in_group("Static") and closing_speed <= impact_tolerance / 2: return false
	return true


# ------------------------------------------------------- Grab / destroy

func _on_dragged() -> void:
	incapacitated = true
	state = State.DRAGGED


func _on_released() -> void:
	comp_timer.start()
	state = State.RELEASED


func destroy():
	remove_from_group("Drones")
	set_deferred("freeze", true)
	$CollisionShape2D.set_deferred("disabled", true)
	hide()
	set_deferred("process_mode", PROCESS_MODE_DISABLED)


func _on_take_damage(amount: int = 1) -> void:
	destroy()
