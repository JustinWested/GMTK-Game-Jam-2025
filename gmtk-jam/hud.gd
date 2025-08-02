extends CanvasLayer

@onready var crosshair: TextureRect = $Crosshair
@onready var interaction_label: Label = $InteractionLabel

func _ready() -> void:
	# Hide the label by default.
	interaction_label.hide()
	
	# This assumes the Player node is in a group named "player".
	# In your Player.gd, add 'add_to_group("player")' in _ready().
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.aimed_at_interactable.connect(_on_player_aimed_at_interactable)
		player.aimed_away.connect(_on_player_aimed_away)

func _on_player_aimed_at_interactable(prompt_text: String) -> void:
	# Change crosshair color to indicate interactability.
	crosshair.modulate = Color.YELLOW
	interaction_label.text = prompt_text
	interaction_label.show()

func _on_player_aimed_away() -> void:
	# Reset crosshair and hide the label.
	crosshair.modulate = Color.WHITE
	interaction_label.hide()
