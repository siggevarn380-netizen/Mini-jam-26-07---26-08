extends RigidBody2D
signal take_damage(dmg: int)
signal toggle_powers

enum DragState{READY, DRAGGED, RELEASED}

const REST_ROTATION: float = 0.0
@export var impact_tolerance : float = 100 #The speed required for a drone to explode when impacting terrain or walls
@export var comp_timer: Timer
@export var speed: float = 300.0
@export var right_stiffness: float = 8.0
@export var max_right_speed: float = 3.0
@onready var target: Node2D = get_tree().get_first_node_in_group("Player")

var dragstate = DragState.READY
var _last_velocity: Vector2 # Stash last speed before impact

func _physics_process(delta: float) -> void:
	match dragstate:
		DragState.READY:
			if not is_instance_valid(target): return
			var dir = (target.global_position - global_position).normalized()
			apply_central_force(dir * speed * mass)
		DragState.DRAGGED:
			pass
		DragState.RELEASED:
			if comp_timer.is_stopped(): dragstate = DragState.READY
			else:
				linear_velocity.y += 10

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	_last_velocity = state.linear_velocity
	if dragstate == DragState.READY:
		var err := angle_difference(rotation, REST_ROTATION)
		state.angular_velocity = clampf(err * right_stiffness, -max_right_speed, max_right_speed)

func _on_body_entered(body: Node) -> void:
	var to_body = (body.global_position - global_position).normalized()
	var closing_speed = _last_velocity.dot(to_body)

	if (body.is_in_group("Player") and dragstate == DragState.READY):
		if !body.is_invulnerable:
			body.take_damage.emit(1)
		take_damage.emit(0)
	if body.is_in_group("Enemies") and dragstate != DragState.READY:
		body.take_damage.emit(1)
		take_damage.emit(0)

func _on_dragged() -> void:
	dragstate = DragState.DRAGGED

func _on_released()     -> void:
	comp_timer.start()
	dragstate = DragState.RELEASED

func destroy():
	set_deferred("freeze", true)
	$CollisionShape2D.set_deferred("disabled", true)
	hide()
	set_deferred("process_mode", PROCESS_MODE_DISABLED)

func _on_take_damage(_dmg: int) -> void:
	destroy()
