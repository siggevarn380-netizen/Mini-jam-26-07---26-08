extends Node

const bedtime = 21.00
var current_time = 23.14

func _ready() -> void:
	if current_time > bedtime:
		print("Go to bed for fucks sake")
		#get_tree().quit()
# This took time to code i could have spent sleeping
	$Drone.toggle_powers.connect($Player.toggle_using_powers)
