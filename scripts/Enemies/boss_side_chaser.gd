extends "res://scripts/Enemies/chaser_drone.gd"  # ← ajustá a la ruta real del script tirador
# Boss line shooter: instead of orbiting the boss in a circle like the
# generic swarm, holds a fixed slot in an arc that always faces the player.
# Falls back to normal swarm behavior if the boss it belongs to dies.

var boss_line: Node2D = null   # Set by the Boss right after spawn
var row_slot: int = 0          # 0..line_count-1, set by the Boss right after spawn

func _enter_seek() -> void:
	if not is_instance_valid(boss_line) or not boss_line.is_in_group("Boss"):
		# Our boss is gone — rejoin the normal formation logic.
		boss_line = null
		super()
		return

	incapacitated = false
	state = State.SEEK
	orbit_boss = boss_line
	if not is_instance_valid(target):
		target = get_tree().get_first_node_in_group("Player")
	hover_dist = boss_line.line_distance
	my_arc = 0.0
	hover_time = 0.0
	linear_damp = 0.0
	seek_elapsed = 0.0

func _hover_angle() -> float:
	if not is_instance_valid(orbit_boss) or orbit_boss != boss_line or not is_instance_valid(target):
		return super()
	var to_player := (target.global_position - orbit_boss.global_position).angle()
	var mid: float = (float(boss_line.line_count) - 1) / 2.0
	var offset: float = (float(row_slot) - mid) * float(boss_line.line_angle_step)
	return to_player + offset
