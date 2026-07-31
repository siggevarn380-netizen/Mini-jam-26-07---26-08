extends CharacterBody2D

var using_powers: bool = false

const SPEED = 300.0
const JUMP_VELOCITY = -400.0

const DASH_SPEED = 900.0
const DASH_TIME = 0.2
const DASH_COOLDOWN = 1.0

var is_dashing = false
var dash_timer = 0.0
var cooldown_timer = 0.0
var dash_direction = 1.0

func _process(delta: float) -> void:
    if cooldown_timer > 0:
        cooldown_timer -= delta

func _physics_process(delta: float) -> void:
    # Add the gravity.
    if not is_on_floor():
        velocity += get_gravity() * delta

    # Handle jump.
    if Input.is_action_just_pressed("ui_accept") and is_on_floor() and !using_powers:
        velocity.y = JUMP_VELOCITY
    
    if is_dashing:
        dash_timer -= delta
        velocity.x = dash_direction * DASH_SPEED
        velocity.y = 0 
        move_and_slide()
        
        if dash_timer <= 0:
            is_dashing = false
        return

    if Input.is_action_just_pressed("dash") and cooldown_timer <= 0 and !using_powers:
        is_dashing = true
        dash_timer = DASH_TIME
        cooldown_timer = DASH_COOLDOWN
        
        var input_dir := Input.get_axis("ui_left", "ui_right")
        if input_dir != 0:
            dash_direction = input_dir
    
    # Get the input direction and handle the movement/deceleration.
    # As good practice, you should replace UI actions with custom gameplay actions.
    var direction := Input.get_axis("ui_left", "ui_right")
    if direction and !using_powers:
        velocity.x = direction * SPEED
    else:
        velocity.x = move_toward(velocity.x, 0, SPEED)

    move_and_slide()

func toggle_using_powers():
    using_powers = !using_powers
    
    
