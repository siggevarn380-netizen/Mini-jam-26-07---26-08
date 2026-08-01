extends RigidBody2D
signal take_damage(dmg: int)
signal toggle_powers
enum DragState{READY, DRAGGED, RELEASED}

@export var impact_tolerance: float = 100 
@export var comp_timer: Timer
@export var speed: float = 200.0
@export var right_stiffness: float = 8.0
@export var max_right_speed: float = 3.0

@export var stop_distance: float = 500.0
@export var resume_distance: float = 700.0 

@export var fire_timer: Timer
const bullet_scene = preload("res://scenes/bullet.tscn")
@export var muzzle: Marker2D
@export var bullet_speed: float = 500.0
@export var bullet_damage: int = 1

@onready var target: Node2D = get_tree().get_first_node_in_group("Player")

var health = 3

var dragstate = DragState.READY
var _last_velocity: Vector2
var _in_range: bool = false

func _physics_process(delta: float) -> void:
    match dragstate:
        DragState.READY:
            if not is_instance_valid(target): return
            var to_target = target.global_position - global_position
            var dist = to_target.length()

            if _in_range:
                if dist > resume_distance:
                    _in_range = false
            else:
                if dist <= stop_distance:
                    _in_range = true

            if _in_range:
                linear_velocity = linear_velocity.move_toward(Vector2.ZERO, speed * delta)
            else:
                var dir = to_target.normalized()
                apply_central_force(dir * speed * mass)
        DragState.DRAGGED:
            pass
        DragState.RELEASED:
            if comp_timer.is_stopped(): dragstate = DragState.READY
            else:
                linear_velocity.y += 10

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
    _last_velocity = state.linear_velocity
    if dragstate == DragState.READY and is_instance_valid(target):
        var target_angle = (target.global_position - global_position).angle()
        var err := angle_difference(rotation, target_angle)
        state.angular_velocity = clampf(err * right_stiffness, -max_right_speed, max_right_speed)

func _on_body_entered(body: Node) -> void:
    var to_body = (body.global_position - global_position).normalized()
    var closing_speed = _last_velocity.dot(to_body)
    if closing_speed < impact_tolerance:
        pass
    else:
        if not body.is_in_group("Static"):
            body.take_damage.emit(1)
        take_damage.emit(1)

func _on_dragged() -> void:
    dragstate = DragState.DRAGGED

func _on_released() -> void:
    comp_timer.start()
    dragstate = DragState.RELEASED

func destroy():
    set_deferred("freeze", true)
    $CollisionShape2D.set_deferred("disabled", true)
    hide()
    set_deferred("process_mode", PROCESS_MODE_DISABLED)

func _on_fire_timer_timeout() -> void:
    if dragstate != DragState.READY: return
    if not _in_range: return
    if not is_instance_valid(target): return
    if bullet_scene == null: return

    var bullet = bullet_scene.instantiate()
    get_tree().current_scene.add_child(bullet)
    bullet.global_position = muzzle.global_position
    var dir = (target.global_position - muzzle.global_position).normalized()
    bullet.speed = bullet_speed
    bullet.damage = bullet_damage
    bullet.launch(dir)

func _on_take_damage(dmg: int) -> void:
    health = maxi(0, health - dmg)
    if health <= 0:
        destroy()

func _set_new_target():
        target = get_tree().get_first_node_in_group("Player")
    
