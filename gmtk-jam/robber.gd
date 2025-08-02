extends CharacterBody3D

# This path will need to be set correctly in the scene.
@onready var game_state_manager: GameStateManager = $"../../../GameStateManager"

func _ready():
	# The Robber subscribes to the events it cares about.
	game_state_manager.robber_enters.connect(_on_robber_enters)
	game_state_manager.robbery_begins.connect(_on_robbery_begins)
	# Other connections...

func _on_robber_enters():
	# Code to make the robber walk through the door.
	print("ROBBER: I'm entering now!")

func _on_robbery_begins():
	# Code to make the robber pull out a weapon and shout.
	print("ROBBER: This is a robbery!")
