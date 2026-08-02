extends Drone

@export var fire_timer: Timer
const bullet_scene = preload("res://scenes/Enemy/bullet.tscn")
@export var muzzle: Marker2D
@export var bullet_speed: float = 500.0
@export var bullet_damage: int = 1
@export var seek_shot_speed: float = 1.5
@export var fire_range: float = 900.0

func _ready() -> void:
	super()
	fire_timer.timeout.connect(_on_fire_timer_timeout)
	fire_timer.start()
func _physics_process(delta: float) -> void:
	print(state, " ", target, " ", hover_dist)
	if state == State.HOVER and is_instance_valid(target) and not _shot_is_clear():
		hover_phase += seek_shot_speed * delta
	super(delta)


func _integrate_forces(body_state: PhysicsDirectBodyState2D) -> void:
	_last_velocity = body_state.linear_velocity
	if (state == State.HOVER or state == State.SEEK) and is_instance_valid(target):
		var target_angle := (target.global_position - global_position).angle()
		var err := angle_difference(rotation, target_angle)
		body_state.angular_velocity = clampf(err * right_stiffness, -max_right_speed, max_right_speed)

func _roll_for_action() -> bool:
	return false

func _on_hover_action() -> void:
	pass
	
func _shot_is_clear() -> bool:
	if not is_instance_valid(target): return false
	var space = get_world_2d().direct_space_state
	var exclude: Array[RID] = [get_rid()]
	if target is PhysicsBody2D:
		exclude.append(target.get_rid())
	for other in get_tree().get_nodes_in_group("Drones"):
		if other is PhysicsBody2D and other != self:
			exclude.append(other.get_rid())
	var q = PhysicsRayQueryParameters2D.create(
		muzzle.global_position, target.global_position, enemy_layer_mask, exclude
	)
	var hit = space.intersect_ray(q)
	return hit.is_empty()

func _on_fire_timer_timeout() -> void:
	if state != State.HOVER: return
	if not is_instance_valid(target): return
	if global_position.distance_to(target.global_position) > fire_range: return
	if not _shot_is_clear(): return
	if bullet_scene == null: return
	var bullet = bullet_scene.instantiate()
	get_tree().current_scene.add_child(bullet)
	bullet.global_position = muzzle.global_position
	var dir = (target.global_position - muzzle.global_position).normalized()
	bullet.speed = bullet_speed
	bullet.damage = bullet_damage
	bullet.launch(dir)
	$AudioStreamPlayer2D.play()
