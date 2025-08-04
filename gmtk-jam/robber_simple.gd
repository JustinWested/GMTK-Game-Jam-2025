class_name RobberSimple
extends CharacterBody3D

@onready var nav_agent = $NavigationAgent3D
@onready var animation_player = $AnimationPlayer

@export var clerk_position = Vector3(0, 1, -8)
@export var exit_position = Vector3(0, 1, 5)
@export var move_speed = 2.5
@export var auto_start_time = 5.0  # Start automatically after this many seconds

var current_state = "idle"
var start_timer = null

func _ready():
	# Fallback behavior that doesn't require GameStateManager
	start_timer = Timer.new()
	start_timer.wait_time = auto_start_time
	start_timer.one_shot = true
	start_timer.timeout.connect(_on_auto_start)
	add_child(start_timer)
	start_timer.start()
	
	global_position = exit_position
	if nav_agent:
		nav_agent.target_position = global_position

func _on_auto_start():
	# Simple automatic behavior without GameStateManager
	current_state = "approaching"
	if nav_agent:
		nav_agent.target_position = clerk_position
	print("ROBBER: Starting automatic robbery sequence")

func _physics_process(delta):
	if nav_agent and not nav_agent.is_navigation_finished():
		var next_position = nav_agent.get_next_path_position()
		var direction = (next_position - global_position).normalized()
		velocity = direction * move_speed
		move_and_slide()
	else:
		if current_state == "approaching":
			current_state = "robbing"
			print("ROBBER: This is a robbery!")
			# Wait 10 seconds then leave
			var leave_timer = Timer.new()
			leave_timer.wait_time = 10.0
			leave_timer.one_shot = true
			leave_timer.timeout.connect(_on_auto_leave)
			add_child(leave_timer)
			leave_timer.start()

func _on_auto_leave():
	current_state = "leaving"
	if nav_agent:
		nav_agent.target_position = exit_position
	print("ROBBER: Leaving the store")