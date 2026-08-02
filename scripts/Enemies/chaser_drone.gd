extends Drone

# Chaser: hovers with the flock, then commits to a straight dash at the player.
#
# The dash sets velocity directly rather than applying force, so it can't be
# dragged into an orbit by the tangential speed it carried out of HOVER.
# Once launched it may only rotate at charge_turn_rate, which is what makes
# the attack readable and dodgeable.

const CHARGE := State._NEXT

@export_group("Charge")
@export var charge_speed: float = 1400   # Must stay well above impact_tolerance to deal damage
@export_range(0.0, 360.0, 1.0, "radians_as_degrees") var charge_turn_rate: float = deg_to_rad(90.0)
@export var charge_time: float = 1.5     # Hard cap on how long a dash stays committed

var charge_elapsed: float = 0.0


func _physics_process(delta: float) -> void:
	if state == CHARGE:
		if not is_instance_valid(target):
			_enter_seek()
			return

		charge_elapsed += delta
		var to_target := target.global_position - global_position

		# Bail on timeout, or once we've overshot and the player is behind us.
		if charge_elapsed > charge_time or linear_velocity.dot(to_target) < 0.0:
			_enter_seek()
			return

		# Rotate toward the player, but no faster than the turn rate allows.
		var err := angle_difference(linear_velocity.angle(), to_target.angle())
		var turn := clampf(err, -charge_turn_rate * delta, charge_turn_rate * delta)
		linear_velocity = linear_velocity.rotated(turn)
		return

	super(delta)


func _roll_for_action() -> bool:
	# Flock-wide cap first: cheapest check, and it skips the raycast below.
	var charging := 0
	for d in get_tree().get_nodes_in_group("Drones"):
		if d.state == CHARGE:
			charging += 1
	if charging >= max_simultaneous_charges:
		return false

	if not _path_is_clear(): return false

	# A fast-moving player is a harder target, so chargers hold back.
	var ratio := clampf(absf(target.velocity.x) / target.max_speed, 0.0, 1.0)
	var chance := pow(1.0 - ratio, 2.0)
	return randf() < chance


func _on_hover_action() -> void:
	# Forced actions reach here without a roll, so re-check line of sight.
	if not _path_is_clear(): return
	_enter_charge()


func _enter_charge() -> void:
	state = CHARGE
	charge_elapsed = 0.0
	linear_damp = 0.0
	# Overwrite velocity outright — any leftover sideways drift would curve the dash.
	linear_velocity = (target.global_position - global_position).normalized() * charge_speed
