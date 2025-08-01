
class_name PlayerController
extends CharacterBody3D

@export var speed: float = 5.0
@export var acceleration: float = 8.0
@export var friction: float = 10.0
@export var visuals_node_path: NodePath
@export var camera_pivot_path: NodePath

var _gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
@onready var _visuals: Node3D = get_node(visuals_node_path)
@onready var _camera_pivot: Node3D = get_node(camera_pivot_path)
@onready var animation_player: AnimationPlayer = $Visuals/rig/AnimationPlayer
@onready var animation_tree: AnimationTree = $Visuals/rig/AnimationPlayer/AnimationTree

func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_handle_movement_and_rotation(delta)
	move_and_slide()
	_update_animations()


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= _gravity * delta


func _handle_movement_and_rotation(delta: float) -> void:
	if not is_instance_valid(_camera_pivot):
		return

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var pivot_basis := _camera_pivot.global_transform.basis
	
	var direction := (pivot_basis.z * input_dir.y + pivot_basis.x * input_dir.x)
	direction.y = 0
	direction = direction.normalized()

	if direction:
		velocity.x = lerp(velocity.x, direction.x * speed, acceleration * delta)
		velocity.z = lerp(velocity.z, direction.z * speed, acceleration * delta)
		
		_visuals.look_at(_visuals.global_position - velocity, Vector3.UP)
	else:
		velocity.x = lerp(velocity.x, 0.0, friction * delta)
		velocity.z = lerp(velocity.z, 0.0, friction * delta)
		

func _update_animations() -> void:
	var horizontal_velocity = Vector2(velocity.x, velocity.z)
	
	# Check if the character is moving on the ground.
	if horizontal_velocity.length() > 0.1:
		# Tell the state machine to travel to the "walk" state.
		# The AnimationTree handles the transition timing for us.
		animation_tree.get("parameters/playback").travel("walking")
	else:
		# Tell the state machine to travel to the "idle" state.
		animation_tree.get("parameters/playback").travel("idle")
