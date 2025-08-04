# res://game_state_manager.gd
# Manages the game's time loop, timeline events, and state transitions.
# It acts as a central broadcaster, emitting signals at key moments that other
# nodes (like NPCs) can listen and react to.
class_name GameStateManager
extends Node

# --- Signals (The Broadcaster) ---
# Emitted when a new loop begins.
signal loop_started
# Emitted when a loop is forcibly reset (e.g., by player death).
signal loop_reset
# Emitted when the loop timer naturally runs out.
signal loop_ended

# --- Timeline-specific events ---
signal robber_enters
signal robbery_begins
signal robbery_concludes
signal robber_leaves


# --- Exports ---
# The total duration of one loop in seconds.
@export var loop_duration: float = 180.0 # 3 minutes

# --- Private Variables ---
@onready var _loop_timer: Timer = $LoopTimer
var _elapsed_time: float = 0.0

# This is the data-driven timeline. To change the game's flow,
# you only need to edit this array.
var _timeline_events := [
	{ "timestamp": 45.0, "signal_name": "robber_enters", "triggered": false },
	{ "timestamp": 50.0, "signal_name": "robbery_begins", "triggered": false },
	{ "timestamp": 105.0, "signal_name": "robbery_concludes", "triggered": false }, # 1m 45s
	{ "timestamp": 115.0, "signal_name": "robber_leaves", "triggered": false }
]


func _ready() -> void:
	# Configure the timer but don't start it yet.
	_loop_timer.wait_time = loop_duration
	_loop_timer.one_shot = true
	# Connect the timer's timeout signal to our end-of-loop function.
	_loop_timer.timeout.connect(_on_loop_timer_timeout)
	
	# Add to group for easier finding
	add_to_group("game_state_manager")
	
	# Start the very first loop.
	start_loop()


func _process(delta: float) -> void:
	# Only process the timeline if the timer is running.
	if not _loop_timer.is_stopped():
		_elapsed_time += delta
		_check_timeline_events()


### Public API Functions ###

# Starts a fresh loop.
func start_loop() -> void:
	_reset_event_flags()
	_elapsed_time = 0.0
	_loop_timer.start()
	emit_signal("loop_started")
	print("Game loop started. Duration: %s seconds." % loop_duration)

# Resets the loop, for example, after the player dies.
func reset_loop() -> void:
	_loop_timer.stop()
	emit_signal("loop_reset")
	# We start a new loop after a brief delay to allow other nodes to reset.
	await get_tree().create_timer(0.1).timeout
	start_loop()


### Private Functions ###

# Checks the timeline array and fires signals for any events whose time has come.
func _check_timeline_events() -> void:
	for event in _timeline_events:
		if not event.triggered and _elapsed_time >= event.timestamp:
			emit_signal(event.signal_name)
			event.triggered = true
			print("Timeline Event: Fired '%s' at %s seconds." % [event.signal_name, _elapsed_time])

# Called automatically when the main loop timer finishes.
func _on_loop_timer_timeout() -> void:
	emit_signal("loop_ended")
	print("Loop ended naturally.")
	# After the loop ends, it resets.
	reset_loop()

# Resets the 'triggered' flag on all timeline events so they can fire again next loop.
func _reset_event_flags() -> void:
	for event in _timeline_events:
		event.triggered = false
