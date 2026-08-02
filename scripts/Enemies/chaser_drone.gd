extends Drone

const CHARGE := State._NEXT

@export_group("Charge")
@export var charge_accel: float = 800
@export var charge_aiming: float = 400

var charge_target: Vector2

func _physics_process(delta: float) -> void:
	if state == CHARGE:
		charge_target = charge_target.move_toward(target.global_position, charge_aiming * delta)
		var dir := (charge_target - global_position).normalized()
		dir = (dir + _get_separation() * 0.5).normalized()
		apply_central_force(dir * charge_accel * mass)
		return
	super(delta)

func _roll_for_action() -> bool:
	if not _path_is_clear(): return false
	var ratio := clampf(absf(target.velocity.x) / target.max_speed, 0.0, 1.0)
	var chance := pow(1.0 - ratio, 2.0)
	return randf() < chance

func _on_hover_action() -> void:
	_enter_charge()
	pass

func _enter_charge() -> void:
	state = CHARGE
	charge_target = target.global_position
	linear_damp = 0.0
