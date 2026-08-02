class_name MainCharacterGraphics
extends Node2D

@onready var sprites: Node2D = $Sprites
@onready var skeleton_2d: Skeleton2D = $Skeleton/Skeleton2D
@onready var skeleton: Node2D = $Skeleton
@onready var ik_targets: Node2D = $IkTargets

@onready var hand_front: Marker2D = $IkTargets/HandFrontAnimated/HandFront

@onready var animation_tree: AnimationTree = $AnimationTree
@onready var shoulder_front: Bone2D = $Skeleton/Skeleton2D/Hip/Chest/ShoulderFront

@onready var hand_front_variant_1: Sprite2D = $Sprites/HandFront/HandFront2/HandFrontVariant1
@onready var hand_front_variant_2: Sprite2D = $Sprites/HandFront/HandFront2/HandFrontVariant2


@export var min_run_velocity: float = 410.0 ## Minimum velocity to transition to running animation from walk
@export var min_target_dist: float = 100
@export var max_target_dist: float = 250.0

var is_mouse_on_right: bool = true

var is_falling: bool = false
var is_facing_left: bool = true
var is_using_powers: bool = false

var state_machine: AnimationNodeStateMachinePlayback
const walk_pos: float = 0.3

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	state_machine = animation_tree.get("parameters/playback")


func _physics_process(_delta: float) -> void:
	if is_using_powers:
		reach_towards_mouse()

func reach_towards_mouse() -> void:
	var mouse_global_pos: Vector2 = get_global_mouse_position()
	var shoulder_global_pos: Vector2 = shoulder_front.global_position
	
	# Vector pointing from shoulder to mouse
	var to_mouse: Vector2 = mouse_global_pos - shoulder_global_pos
	
	# Update side tracking (true if mouse is to the right of the shoulder in world space)
	is_mouse_on_right = to_mouse.x >= 0.0
	
	hand_front.global_position = mouse_global_pos


func jump():
	state_machine.travel("Jump")
	is_falling = true

func land():
	state_machine.travel("Fall")
	is_falling = false


func die():
	state_machine.travel("Death")


func take_damage():
	state_machine.travel("Damage")


func dash():
	state_machine.travel("Dash")


func set_power_use(is_using: bool = false):
	turn_on_hand_front_animation(not is_using)
	is_using_powers = is_using
	hand_front_variant_1.visible = is_using
	hand_front_variant_2.visible = not is_using


func set_velocity(new_velocity: Vector2):
	set_velocity_x(new_velocity.x)


func set_velocity_x(
	velocity_x: float
):
	var vel_input: float = 0.0
	if abs(velocity_x) <= min_run_velocity:
		vel_input = abs(velocity_x) / min_run_velocity * walk_pos
	else:
		vel_input = 0.5
	
	if not is_using_powers:
		if velocity_x != 0:
			# follow walk direction
			update_facing_direction(velocity_x < 0)
			vel_input *= -1
	else:
		update_facing_direction(not is_mouse_on_right)
		if not is_mouse_on_right:
			if velocity_x < 0:
				vel_input *= -1
		else:
			if velocity_x > 0:
				vel_input *= -1
	
	animation_tree.set("parameters/WalkRun_Blendspace1/blend_position", vel_input)


func update_facing_direction(is_walking_left: bool = true):
	if is_facing_left:
		if not is_walking_left:
			# swap to face right
			set_facing_right(true)
			is_facing_left = false
	else:
		if is_walking_left:
			# swap to face left
			set_facing_right(false)
			is_facing_left = true


func set_facing_right(is_right: bool = true):
	print("set_facing_right: ", is_right )
	
	var facing_scale = -1.0 if is_right else 1.0
	
	# Apply scale to visual nodes
	skeleton.scale.x = facing_scale
	sprites.scale.x = facing_scale
	ik_targets.scale.x = facing_scale
	
	## Get the modification stack from Skeleton2D
	#var modification_stack = skeleton_2d.get_modification_stack()
	#
	## Foot Front
	#set_ik_mod_two_bone_bend_direction(modification_stack, 0, is_right)
	#
	## Foot Back
	#set_ik_mod_two_bone_bend_direction(modification_stack, 1, is_right)
	#
	## Hand Front
	#set_ik_mod_two_bone_bend_direction(modification_stack, 2, not is_right)
	#
	## Hand Back
	#set_ik_mod_two_bone_bend_direction(modification_stack, 3, not is_right)


func set_ik_mod_two_bone_bend_direction(
	mod_stack: SkeletonModificationStack2D,
	mod_idx: int,
	flip: bool = false
):
	if not mod_stack:
		return
		
	var ik_mod = mod_stack.get_modification(mod_idx)
	
	if ik_mod and "flip_bend_direction" in ik_mod:
		ik_mod.flip_bend_direction = flip


func turn_on_hand_front_animation(turn_on: bool):
	if turn_on:
		# Return control to the animation system
		hand_front.top_level = false
		hand_front.position = Vector2.ZERO
	else:
		# Detach for custom IK / power logic
		# First snap to current global position of parent so it doesn't jump/stick
		hand_front.global_position = hand_front.get_parent().global_position
		hand_front.top_level = true
	pass
