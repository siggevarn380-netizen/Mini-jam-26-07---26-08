extends CharacterBody2D

signal take_damage
signal gain_heart

@export_group("Nodes")
@export var power: Area2D
@export_group("Basic Movement")
@export var base_speed = 400.0
@export var sprint_speed = 600.0
@export var accel = 200.0
@export var max_speed: float = 1000
@export_group("Jump")
@export var jump_vel = 400.0
@export_group("Dash")
@export var dash_speed = 3000.0
@export var dash_cooldown = 1.0
@export_group("Other")
@export var base_power_range: float = 300


var dash_cooldown_timer = 0.0
var power_range = base_power_range

func _process(delta: float) -> void:
	dash_cooldown_timer = maxf(dash_cooldown_timer - delta, 0.0)
	
func _physics_process(delta: float) -> void:
	# [INPUT]
	var direction := Input.get_axis("Left", "Right")
	var dash = Input.get_axis("Dash_Left", "Dash_Right")
	var jump = Input.is_action_just_pressed("Jump")
	var sprinting = Input.is_action_pressed("Sprint")
	var click = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	# [CALCULATIONS]
	var speed = sprint_speed if sprinting else base_speed
	var target_vel = speed * direction if direction else 0.0
	# [APPLY]
	if !is_on_floor():
		velocity += get_gravity() * delta

	if jump and is_on_floor(): velocity.y = -jump_vel
	
	if dash and dash_cooldown_timer == 0.0:
		velocity.x += dash_speed * dash
		dash_cooldown_timer = dash_cooldown
	else:
		velocity.x = move_toward(velocity.x, target_vel, accel)
	move_and_slide()
	
	if click:
		var to_mouse = get_global_mouse_position() - global_position
		var pos = global_position + to_mouse.limit_length(power_range)
		power._apply_power(pos)
	else:
		power._disable_power()
	power.moving = absf(velocity.x) >= 10.0
		

func add_potency(amount: float) -> void:
	PlayerData.score += amount
	power.max_size += amount
	power_range += amount
	print("max size: ", power.max_size, "max range: ", power_range)

func add_heart(amount: int) -> void:
	PlayerData.score += 10
	gain_heart.emit(amount)
func _on_player_health_death() -> void:
	pass # Replace with function body.
