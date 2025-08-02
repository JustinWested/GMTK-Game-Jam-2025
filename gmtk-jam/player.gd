class_name PlayerController
extends CharacterBody3D

signal aimed_at_interactable(prompt_text: String)
signal aimed_away

# --- Exports ---
@export_group("Movement")
@export var walk_speed: float = 1.1
@export var sneak_speed: float = 0.8
@export var acceleration: float = 8.0
@export var friction: float = 10.0

@export_group("Components")
@export var visuals_node_path: NodePath
@export var camera_pivot_path: NodePath

@export_group("Animation")
@export var blend_speed = 15.0

# --- Private State Variables ---
enum {IDLE, WALK, CROUCH, SNEAK}
var _current_state = IDLE
var _is_crouching = false

var _current_target: Interactable = null
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var _visuals: Node3D = get_node(visuals_node_path)
@onready var _camera_pivot: Node3D = get_node(camera_pivot_path)
@onready var _animation_tree: AnimationTree = $Visuals/rig/AnimationPlayer/AnimationTree
@onready var interaction_raycast: RayCast3D = $CameraPivot/RayCast3D


func _physics_process(delta: float) -> void:
	# The order of operations is important.
	_update_state() # First, figure out what state we should be in.
	_apply_gravity(delta)
	_handle_movement_and_rotation(delta) # Then, calculate movement based on that state.
	move_and_slide()
	_handle_animations(delta) # Finally, update the animations based on the state.
	_handle_interaction_detection()
	_handle_interaction_input()

# --- MODIFIED: State Management ---
# The call to the physics function has been removed.
func _update_state() -> void:
	# 1. Check for crouch input.
	if Input.is_action_just_pressed("crouch"): # Use an Input Map action named "crouch".
		_is_crouching = not _is_crouching
		
	# 2. Check for movement input.
	var is_moving = Input.get_vector("move_left", "move_right", "move_forward", "move_back").length() > 0.1

	# 3. Determine the final state based on crouch status and movement.
	if _is_crouching:
		if is_moving:
			_current_state = SNEAK
		else:
			_current_state = CROUCH
	else:
		if is_moving:
			_current_state = WALK
		else:
			_current_state = IDLE


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta


# --- MODIFIED: Movement Handling ---
# This function is the same, but now relies on the simpler state logic.
func _handle_movement_and_rotation(delta: float) -> void:
	if not is_instance_valid(_camera_pivot):
		return

	# Determine the current speed based on our state.
	var current_speed = walk_speed if not _is_crouching else sneak_speed

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var pivot_basis := _camera_pivot.global_transform.basis
	
	var direction := (pivot_basis.z * input_dir.y + pivot_basis.x * input_dir.x)
	direction.y = 0
	direction = direction.normalized()

	if direction:
		velocity.x = lerp(velocity.x, direction.x * current_speed, acceleration * delta)
		velocity.z = lerp(velocity.z, direction.z * current_speed, acceleration * delta)
		
		_visuals.look_at(_visuals.global_position - velocity, Vector3.UP)
	else:
		velocity.x = lerp(velocity.x, 0.0, friction * delta)
		velocity.z = lerp(velocity.z, 0.0, friction * delta)


# --- UNCHANGED: Animation Handling ---
# This function remains exactly the same and works perfectly.
func _handle_animations(delta: float) -> void:
	var walk_target = 1.0 if _current_state == WALK else 0.0
	var crouch_target = 1.0 if _current_state == CROUCH else 0.0
	var sneak_target = 1.0 if _current_state == SNEAK else 0.0
	
	# Update the blend amounts in the AnimationTree.
	_animation_tree["parameters/Walking/blend_amount"] = lerp(_animation_tree["parameters/Walking/blend_amount"], walk_target, blend_speed * delta)
	_animation_tree["parameters/Crouching/blend_amount"] = lerp(_animation_tree["parameters/Crouching/blend_amount"], crouch_target, blend_speed * delta)
	_animation_tree["parameters/Sneaking/blend_amount"] = lerp(_animation_tree["parameters/Sneaking/blend_amount"], sneak_target, blend_speed * delta)


# --- Add this new private function at the bottom ---
func _handle_interaction_detection() -> void:
	var new_target: Interactable = null
	if interaction_raycast.is_colliding():
		# Cast the collider to see if it's a class that extends Interactable.
		new_target = interaction_raycast.get_collider() as Interactable

	# If our target has changed...
	if new_target != _current_target:
		# If we were looking at something before, tell it to unhighlight.
		if is_instance_valid(_current_target):
			_current_target.unhighlight()
			emit_signal("aimed_away")

		# Update our target.
		_current_target = new_target
		
		# If we are now looking at a valid interactable, highlight it.
		if is_instance_valid(_current_target):
			_current_target.highlight()
			emit_signal("aimed_at_interactable", _current_target.interaction_prompt)

func _handle_interaction_input() -> void:
	# Checks the global Input state for the 'interact' action.
	# This is robust and won't conflict with mouse motion events.
	if Input.is_action_just_pressed("interact") and is_instance_valid(_current_target):
		_current_target.interact(self)
