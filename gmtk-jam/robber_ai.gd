# res://robber_ai.gd
class_name RobberAI
extends CharacterBody3D

enum State { IDLE, ENTERING, APPROACHING, ROBBING, LEAVING, ESCAPED }

@onready var nav_agent = $NavigationAgent3D
@onready var animation_player = $AnimationPlayer
var game_state_manager = null  # Will be found dynamically

@export var clerk_position = Vector3(0, 1, -8)  # Make these exportable
@export var exit_position = Vector3(0, 1, 5)
@export var move_speed = 2.5

var current_state = State.IDLE

func _ready():
	# Find GameStateManager with multiple fallback methods
	_find_game_state_manager()
	
	if game_state_manager:
		# Connect to game state signals with error checking
		game_state_manager.robber_enters.connect(_on_robber_enters)
		game_state_manager.robbery_begins.connect(_on_robbery_begins)
		game_state_manager.robbery_concludes.connect(_on_robbery_concludes)
		game_state_manager.robber_leaves.connect(_on_robber_leaves)
		print("ROBBER: Connected to GameStateManager")
	else:
		push_error("ROBBER: Could not find GameStateManager!")
	
	# Set initial position
	global_position = exit_position
	if nav_agent:
		nav_agent.target_position = global_position

func _find_game_state_manager():
	# Try multiple paths to find GameStateManager
	var possible_paths = [
		"../GameStateManager",
		"../../GameStateManager", 
		"../../../GameStateManager",
		"/root/Main/GameStateManager",
		"/root/GameStateManager"
	]
	
	for path in possible_paths:
		game_state_manager = get_node_or_null(path)
		if game_state_manager and game_state_manager.has_signal("robber_enters"):
			print("ROBBER: Found GameStateManager at path: ", path)
			return
	
	# Last resort - search by group
	game_state_manager = get_tree().get_first_node_in_group("game_state_manager")
	if game_state_manager:
		print("ROBBER: Found GameStateManager via group")
	else:
		# Final fallback - search by script name
		for node in get_tree().get_nodes_in_group(""):
			if node and node.get_script() and node.get_script().resource_path.ends_with("game_state_manager.gd"):
				game_state_manager = node
				print("ROBBER: Found GameStateManager via script search")
				break

func _physics_process(delta):
	if not game_state_manager:
		return  # Don't process if no game state manager
	
	match current_state:
		State.ENTERING, State.APPROACHING, State.LEAVING:
			if nav_agent and is_instance_valid(nav_agent):
				_handle_movement(delta)

func _handle_movement(delta):
	if nav_agent.is_navigation_finished():
		_on_destination_reached()
		return
	
	var next_position = nav_agent.get_next_path_position()
	var direction = (next_position - global_position).normalized()
	
	velocity = direction * move_speed
	move_and_slide()

func _on_robber_enters():
	if not is_instance_valid(game_state_manager):
		return
	
	current_state = State.ENTERING
	if nav_agent:
		nav_agent.target_position = clerk_position
	_play_animation("walk")
	print("ROBBER: Entering the store...")

func _on_robbery_begins():
	if not is_instance_valid(game_state_manager):
		return
		
	current_state = State.ROBBING
	_play_animation("point_gun")
	print("ROBBER: This is a robbery! Nobody move!")

func _on_robbery_concludes():
	if not is_instance_valid(game_state_manager):
		return
		
	current_state = State.LEAVING
	if nav_agent:
		nav_agent.target_position = exit_position
	_play_animation("walk")
	print("ROBBER: Got what I came for...")

func _on_robber_leaves():
	if not is_instance_valid(game_state_manager):
		return
		
	current_state = State.ESCAPED
	_play_animation("idle")
	print("ROBBER: Escaped successfully")

func _on_destination_reached():
	match current_state:
		State.ENTERING:
			current_state = State.APPROACHING
			if nav_agent:
				nav_agent.target_position = clerk_position
		State.APPROACHING:
			# Wait for robbery to begin via game state
			pass
		State.LEAVING:
			if global_position.distance_to(exit_position) < 1.0:
				if game_state_manager and game_state_manager.has_method("emit_signal"):
					game_state_manager.emit_signal("robber_leaves")

func _play_animation(anim_name: String):
	if animation_player and animation_player.has_animation(anim_name):
		animation_player.play(anim_name)
	else:
		print("ROBBER: Animation '", anim_name, "' not found")

func get_current_state() -> String:
	return RobberAI.State.keys()[current_state]
