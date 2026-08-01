extends Node2D

@export var drone_list: Array [DroneEntry]
@export var spawn_interval: float = 10.0

var spawn_elapsed = 0.0

func _process(delta: float) -> void:
	spawn_elapsed = minf(spawn_elapsed + delta, spawn_interval)
	if spawn_elapsed == spawn_interval:
		spawn_drone()
		spawn_elapsed = 0.0
		print("Spawning drone")
func pick() -> PackedScene:
	var total = 0.0
	for d in drone_list:
		total += d.common
	
	var roll = randf() * total
	for d in drone_list:
		roll -= d.common
		if roll < 0.0:
			return d.scene
	return null
		
func spawn_drone() -> void:
	var scene = pick()
	if scene == null: return
	var drone = scene.instantiate()
	get_tree().current_scene.add_child(drone)
	drone.global_position = global_position
