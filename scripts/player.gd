extends CharacterBody2D

var using_powers: bool = false

@export_group("Basic Movement")
@export var base_speed = 400.0
@export var sprint_speed = 600.0
@export var accel = 200.0
@export_group("Jump")
@export var jump_vel = 400.0
@export_group("Dash")
@export var dash_speed = 3000.0
@export var dash_time = 0.2
@export var dash_cooldown = 1.0
@export_group("Health & Damage")
@export var starting_health: int = 5

var is_dashing = false
var dash_timer = 0.0
var dash_cooldown_timer = 0.0
var dash_direction = 1.0
var current_health: int = starting_health

func _process(delta: float) -> void:
	dash_cooldown_timer = maxf(dash_cooldown_timer - delta, 0.0)

func _physics_process(delta: float) -> void:
	# [INPUT]
	var direction := Input.get_axis("Left", "Right")
	var dash = Input.get_axis("Dash_Left", "Dash_Right")
	var jump = Input.is_action_just_pressed("Jump")
	var sprinting = Input.is_action_pressed("Sprint")
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

func toggle_using_powers():
	using_powers = !using_powers

func take_damage(amount: int):
	current_health -= amount
	print("Remaining health:", current_health)
	
