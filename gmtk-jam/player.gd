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
@export var hand_position_helper: Marker3D
@export var item_container: Node3D


@export_group("Animation")
@export var blend_speed = 5.0


# --- Private State Variables ---
enum {IDLE, WALK, CROUCH, SNEAK, CARRY_IDLE, CARRY_MOVING}
var _current_state = IDLE
var _is_crouching = false
var _held_items: Array[Node3D] = []

var _current_target: Interactable = null
var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")


var _carry_master_blend: float = 0.0
var _crouch_master_blend: float = 0.0
var _walk_blend: float = 0.0
var _sneak_blend: float = 0.0
var _carry_walk_blend: float = 0.0

@onready var _visuals: Node3D = get_node(visuals_node_path)
@onready var _camera_pivot: Node3D = get_node(camera_pivot_path)
@export var _animation_tree: AnimationTree
@onready var interaction_raycast: RayCast3D = $CameraPivot/RayCast3D





func _physics_process(delta: float) -> void:
	# The order of operations is important.
	_update_state() # First, figure out what state we should be in.
	_apply_gravity(delta)
	_handle_movement_and_rotation(delta) # Then, calculate movement based on that state.
	move_and_slide()
	_handle_animations(delta) # Finally, update the animations based on the state.
	_handle_interaction_detection()
	_update_carry_volume_position(delta)
	_handle_drop_input()
	
	if Input.is_action_just_pressed("interact"):
		print("1. [PLAYER] 'interact' key pressed.")
		if is_instance_valid(_current_target):
			print("2. [PLAYER] Target '%s' is valid. Calling its interact() function." % _current_target.get_parent().name)
			_current_target.interact(self, item_container)
		else:
			print("2. [PLAYER] No valid target to interact with.")

func start_new_loop() -> void:
	print("[PLAYER] New loop started. Clearing held items and resetting state.")
	
	# Clear the array of any old items.
	for item in _held_items:
		if is_instance_valid(item):
			item.queue_free() # Clean up old items from memory.
	_held_items.clear()
	
	# Explicitly reset the state machine.
	_current_state = IDLE
	_is_crouching = false


func _update_state() -> void:
	var is_moving = Input.get_vector("move_left", "move_right", "move_forward", "move_back").length() > 0.1
	
	if not _held_items.is_empty():
		_is_crouching = false 
		if is_moving:
			_current_state = CARRY_MOVING 
		else:
			_current_state = CARRY_IDLE   
		return 
	
	if Input.is_action_just_pressed("crouch"): 
		_is_crouching = not _is_crouching
		

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



func _handle_movement_and_rotation(delta: float) -> void:
	if not is_instance_valid(_camera_pivot):
		return

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



# The final, robust animation handling function with safeguards.
func _handle_animations(delta: float) -> void:
	# --- 1. Determine Target Values (0.0 or 1.0) ---
	# This logic is clean and based directly on the current state.
	var carry_master_target: float = 1.0 if (_current_state == CARRY_IDLE or _current_state == CARRY_MOVING) else 0.0
	var crouch_master_target: float = 1.0 if (_current_state == CROUCH or _current_state == SNEAK) else 0.0
	var walk_target: float = 1.0 if _current_state == WALK else 0.0
	var sneak_target: float = 1.0 if _current_state == SNEAK else 0.0
	var carry_walk_target: float = 1.0 if _current_state == CARRY_MOVING else 0.0

	# --- 2. Update Our Script's State Variables via Lerp ---
	# We read from our own script variables and interpolate towards the target.
	_carry_master_blend = lerp(_carry_master_blend, carry_master_target, blend_speed * delta)
	_crouch_master_blend = lerp(_crouch_master_blend, crouch_master_target, blend_speed * delta)
	_walk_blend = lerp(_walk_blend, walk_target, blend_speed * delta)
	_sneak_blend = lerp(_sneak_blend, sneak_target, blend_speed * delta)
	_carry_walk_blend = lerp(_carry_walk_blend, carry_walk_target, blend_speed * delta)

	# --- 3. THE SAFEGUARD: Clamp all values ---
	# This forces every blend value to stay within the valid 0.0 to 1.0 range.
	# This will absolutely prevent the "runaway value" bug, regardless of its cause.
	_carry_master_blend = clamp(_carry_master_blend, 0.0, 1.0)
	_crouch_master_blend = clamp(_crouch_master_blend, 0.0, 1.0)
	_walk_blend = clamp(_walk_blend, 0.0, 1.0)
	_sneak_blend = clamp(_sneak_blend, 0.0, 1.0)
	_carry_walk_blend = clamp(_carry_walk_blend, 0.0, 1.0)

	# --- 4. Assign the Safe Values to the AnimationTree ---
	# This is the safe, write-only operation.
	_animation_tree["parameters/CarryMasterBlend/blend_amount"] = _carry_master_blend
	_animation_tree["parameters/Crouching/blend_amount"] = _crouch_master_blend
	_animation_tree["parameters/Walking/blend_amount"] = _walk_blend
	_animation_tree["parameters/Sneaking/blend_amount"] = _sneak_blend
	_animation_tree["parameters/CarryWalking/blend_amount"] = _carry_walk_blend




func _handle_interaction_detection() -> void:
	var new_target: Interactable = null
	if interaction_raycast.is_colliding():
		new_target = interaction_raycast.get_collider() as Interactable

	if new_target != _current_target:
		if is_instance_valid(_current_target):
			_current_target.unhighlight()
			emit_signal("aimed_away")

		# Update our target.
		_current_target = new_target
		
		# If we are now looking at a valid interactable, highlight it.
		if is_instance_valid(_current_target):
			_current_target.highlight()
			emit_signal("aimed_at_interactable", _current_target.interaction_prompt)


func set_held_item(item: Node3D) -> void:
	print("4. [PLAYER] set_held_item() called. Adding '%s' to held items." % item.name)
	_held_items.append(item)

func _update_carry_volume_position(delta: float) -> void:
	if not _held_items.is_empty():
		# The CarryVolume's global position will smoothly follow the hand marker's global position.
		# The lerp acts as a low-pass filter, smoothing out the jitter from the animation.
		$CarryVolume.global_position = $CarryVolume.global_position.lerp(
			hand_position_helper.global_position, 
			15.0 * delta # The '15.0' is a smoothing factor you can adjust.
		)

func get_held_item_count() -> int:
	return _held_items.size()

func _handle_drop_input() -> void:
	# Check if the drop action was pressed and if we are actually holding anything.
	if Input.is_action_just_pressed("drop_items") and not _held_items.is_empty():
		
		print("[PLAYER] Drop command received. Dropping all %s items." % _held_items.size())
		
		# Iterate through every item we are currently holding.
		for item in _held_items:
			# Ensure the item is still valid before trying to free it.
			if is_instance_valid(item):
				# As requested, for now we just make the item disappear forever.
				item.queue_free()
				
		# --- This is the most critical step ---
		# After freeing the nodes, we MUST clear the array.
		# This tells our state machine that our hands are now empty.
		_held_items.clear()
