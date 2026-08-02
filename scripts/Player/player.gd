extends CharacterBody2D

signal take_damage(amount: int)
signal gain_heart
signal been_defeated
signal victory #Emited when the boss is defeated

var track_1 = preload("res://SFX/PickupItem.wav")

@export_group("Nodes")
@export var power: Area2D
@export_group("Basic Movement")
@export var base_speed = 400.0
@export var sprint_speed = 600.0
@export var power_use_speed = 250
@export var accel = 200.0
@export var max_speed: float = 1000
@export_group("Jump")
@export var jump_vel = 400.0
@export_group("Dash")
@export var dash_speed = 3000.0
@export var dash_cooldown = 1.0
@export_group("Other")
@export var base_power_range: float = 300

@onready var graphics: MainCharacterGraphics = $Graphics

var is_falling: bool = false
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
	var using_powers = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	# [CONDITIONS]
	if using_powers:
		dash = false
		jump = false
		sprinting = false
		
		var to_mouse = get_global_mouse_position() - global_position
		var pos = global_position + to_mouse.limit_length(power_range)
		power._apply_power(pos)
		graphics.set_power_use(true)
		
	else:
		power._disable_power()
		graphics.set_power_use(false)
	# [CALCULATIONS]
	var speed = _handle_speed(sprinting, using_powers)
	var target_vel = speed * direction if direction else 0.0
	# [APPLY]
	if !is_on_floor():
		velocity += get_gravity() * delta
	else:
		if is_falling:
			is_falling = false
			graphics.land()

	if jump and is_on_floor():
		velocity.y = -jump_vel
		is_falling = true
		graphics.jump()

	
	if dash and dash_cooldown_timer == 0.0:
		velocity.x += dash_speed * dash
		dash_cooldown_timer = dash_cooldown
		graphics.dash()
		
	else:
		velocity.x = move_toward(velocity.x, target_vel, accel)
	move_and_slide()
	graphics.set_velocity(velocity)
	


func _handle_speed(sprinting: bool, using_powers: bool) -> float:
	if using_powers: return power_use_speed
	if sprinting: return sprint_speed
	return base_speed


func add_potency(amount: float) -> void:
	PlayerData.score += amount
	power.set_radius(power.radius + amount)
	power_range += amount
	print("radius: ", power.radius, " range: ", power_range)

func add_heart(amount: int) -> void:
	PlayerData.score += 10
	gain_heart.emit(amount)
	
func _on_player_health_death() -> void:
	been_defeated.emit()

func pick_up_item():
	$SFXs.stream = track_1
	$SFXs.play()
