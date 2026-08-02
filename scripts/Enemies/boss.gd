extends Drone

@export_group("Boss")
@export var boss_height: float = 380.0
@export var spawner: DroneSpawner

@export_group("Flock")
@export var flock_orbit_radius: float = 160.0
@export var flock_orbit_speed: float = 1.0
@export var flock_max_charges: int = 2
@export var flock_ring_spacing: float = 0.0

@export_group("Shooter Line")
@export var shooter_scene: PackedScene
@export var line_count: int = 4
@export var line_distance: float = 260.0
@export var line_angle_step: float = deg_to_rad(12.0)

@export_group("Side Chasers")
@export var chaser_scene: PackedScene
@export var chaser_spawn_interval: float = 6.0
@export var chaser_side_offset: float = 300.0

var _line: Array = []
var _line_alive: int = 0
var _resetting_line: bool = false
var _chaser_timer: Timer


func _ready() -> void:
	orbit_boss = null
	super()
	for d in get_tree().get_nodes_in_group("Drones"):
		d.orbit_radius = flock_orbit_radius
		d.orbit_speed = flock_orbit_speed
		d.max_simultaneous_charges = flock_max_charges

	_spawn_line()

	_chaser_timer = Timer.new()
	_chaser_timer.wait_time = chaser_spawn_interval
	_chaser_timer.autostart = true
	_chaser_timer.timeout.connect(_on_chaser_timer_timeout)
	add_child(_chaser_timer)


func _enter_seek() -> void:
	incapacitated = false
	state = State.SEEK
	if not is_instance_valid(target):
		target = get_tree().get_first_node_in_group("Player")
	hover_dist = boss_height
	my_arc = minf(hover_arc, max_arc)
	hover_time = 0.0
	linear_damp = 0.0
	seek_elapsed = 0.0


## El jefe siempre queda directamente arriba del jugador, sin sweep.
func _hover_angle() -> float:
	return -PI / 2.0


## Only drones the player has thrown can hurt it.
func _on_body_entered(body: Node) -> void:
	if body.is_in_group("Drones") and body.state != State.RELEASED:
		return
	super(body)


func destroy() -> void:
	remove_from_group("Boss")
	for d in get_tree().get_nodes_in_group("Drones"):
		d.orbit_boss = null
		d._enter_seek()
	super()
	SceneManager.goto_scene("res://scenes/Boot/epilogue_scene.tscn")


func _on_boss_health_died() -> void:
	destroy()


func _on_boss_health_health_changed(current: int, maximum: int) -> void:
	if current <= 0: return
	_reset_line()


func apply_flock_settings(d: Drone) -> void:
	d.orbit_radius = flock_orbit_radius
	d.orbit_speed = absf(flock_orbit_speed)
	d.max_simultaneous_charges = flock_max_charges
	d.orbit_ring_spacing = flock_ring_spacing


# ------------------------------------------------------------- Shooter line

func _spawn_line() -> void:
	_line.clear()
	_line_alive = 0
	for i in line_count:
		var d = spawner.spawn_at(shooter_scene, global_position)
		if d == null: continue
		d.boss_line = self
		d.row_slot = i
		if not d.was_destroyed.is_connected(_on_line_shooter_destroyed):
			d.was_destroyed.connect(_on_line_shooter_destroyed)
		_line.append(d)
		_line_alive += 1


func _on_line_shooter_destroyed(_reward: int) -> void:
	_line_alive -= 1
	if _line_alive <= 0:
		_reset_line()


func _reset_line() -> void:
	if _resetting_line: return
	_resetting_line = true
	for d in _line:
		if is_instance_valid(d):
			if d.was_destroyed.is_connected(_on_line_shooter_destroyed):
				d.was_destroyed.disconnect(_on_line_shooter_destroyed)
			d.destroy()
	_line.clear()
	_line_alive = 0
	_spawn_line()
	_resetting_line = false


# ------------------------------------------------------------- Side chasers

func _on_chaser_timer_timeout() -> void:
	if chaser_scene == null or spawner == null: return
	var left := global_position + Vector2(-chaser_side_offset, 0)
	var right := global_position + Vector2(chaser_side_offset, 0)
	spawner.spawn_at(chaser_scene, left)
	spawner.spawn_at(chaser_scene, right)
