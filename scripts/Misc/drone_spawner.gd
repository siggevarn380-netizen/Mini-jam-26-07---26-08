extends Node2D

@export var drone_list: Array[DroneEntry]
@export var spawn_interval: float = 10.0
@export var cluster_radius: float = 70.0
@export var retry_interval: float = 1.0     # wait this long when the field is full

var spawn_elapsed = 0.0


func _process(delta: float) -> void:
	spawn_elapsed += delta
	if spawn_elapsed >= spawn_interval:
		spawn_elapsed = 0.0
		print("live=", live_drone_count(), " cap=", PlaceholderAutoload.DroneCap)
		if not spawn_drone():
			spawn_elapsed = spawn_interval - retry_interval


func live_drone_count() -> int:
	var n := 0
	for d in get_tree().get_nodes_in_group("Enemies"):
		if is_instance_valid(d) and not d.is_queued_for_deletion() and not d.is_in_group("Boss"):
			n += 1
	return n


func pick() -> DroneEntry:
	var total = 0.0
	for d in drone_list:
		total += d.common

	var roll = randf() * total
	for d in drone_list:
		roll -= d.common
		if roll < 0.0:
			return d
	return null


func spawn_drone() -> bool:
	var room: int = PlaceholderAutoload.DroneCap - live_drone_count()
	if room <= 0:
		return false

	var entry = pick()
	if entry == null or entry.scene == null:
		return false

	var count: int = mini(maxi(1, entry.cluster), room)
	var angle_offset := randf() * TAU

	for i in count:
		var drone = entry.scene.instantiate()
		get_tree().current_scene.add_child(drone)

		var offset := Vector2.ZERO
		if count > 1:
			var angle := angle_offset + TAU * float(i) / float(count)
			var dist := cluster_radius * (0.6 + randf() * 0.4)
			offset = Vector2.RIGHT.rotated(angle) * dist

		drone.global_position = global_position + offset

	print("Spawned ", count, "/", entry.cluster, " — live: ", live_drone_count(), "/", PlaceholderAutoload.DroneCap)
	return true
