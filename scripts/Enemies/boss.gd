extends Drone

@export_group("Boss")
@export var boss_height: float = 380.0
@export_group("Flock")
@export var flock_orbit_radius: float = 160.0
@export var flock_orbit_speed: float = 1.0
@export var flock_max_charges: int = 2
@export var flock_ring_spacing: float = 0.0

func _ready() -> void:
	orbit_boss = null
	super()
	for d in get_tree().get_nodes_in_group("Drones"):
		d.orbit_radius = flock_orbit_radius
		d.orbit_speed = flock_orbit_speed
		d.max_simultaneous_charges = flock_max_charges


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


func _should_retreat(_body: Node2D, _closing_speed: float) -> bool:
	return false


func _on_dragged() -> void:
	pass


func _on_released() -> void:
	pass


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


func _on_boss_health_died() -> void:
	destroy()
	
func apply_flock_settings(d: Drone) -> void:
	d.orbit_radius = flock_orbit_radius
	d.orbit_speed = absf(flock_orbit_speed)
	d.max_simultaneous_charges = flock_max_charges
	d.orbit_ring_spacing = flock_ring_spacing
