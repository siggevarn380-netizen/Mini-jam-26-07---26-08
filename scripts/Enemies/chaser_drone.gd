extends RigidBody2D
signal take_damage(dmg: int)
signal toggle_powers

enum State{HOVER, READY, DRAGGED, RELEASED}

const REST_ROTATION: float = 0.0
@export var impact_tolerance : float = 100 #The speed required for a drone to explode when impacting terrain or walls
@export var comp_timer: Timer
@export var speed: float = 300.0
@export var right_stiffness: float = 8.0
@export var max_right_speed: float = 3.0
@onready var target: Node2D = get_tree().get_first_node_in_group("Player")

var state = State.READY
var _last_velocity: Vector2 # Stash last speed before impact

func _physics_process(delta: float) -> void:
	match state:
		State.HOVER:
			pass #Waiting for right moment
		State.READY:
			if not is_instance_valid(target): return
			var dir = (target.global_position - global_position).normalized()
			apply_central_force(dir * speed * mass)
		State.DRAGGED:
			pass
		State.RELEASED:
			if comp_timer.is_stopped(): state = State.READY
			else:
				linear_velocity.y += 10

func _integrate_forces(body_state: PhysicsDirectBodyState2D) -> void:
	_last_velocity = body_state.linear_velocity
	if state == State.HOVER:
		var err := angle_difference(rotation, REST_ROTATION)
		body_state.angular_velocity = clampf(err * right_stiffness, -max_right_speed, max_right_speed)

func _on_body_entered(body: Node) -> void:

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
