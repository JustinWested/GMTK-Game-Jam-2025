class_name Interactable
extends StaticBody3D 
@export var interaction_prompt: String = "GRAB"

var _highlight_component: HighlightComponent

func _ready() -> void:
	# Find the highlight component. We assume it's a child.
	_highlight_component = find_child("HighlightComponent", true, false)
	if not _highlight_component:
		push_warning("Interactable object '%s' has no HighlightComponent child." % self.name)

func highlight() -> void:
	if _highlight_component:
		_highlight_component.apply_highlight()

func unhighlight() -> void:
	if _highlight_component:
		_highlight_component.remove_highlight()


func interact(interactor: Node, container: Node3D) -> void:
	# Disable the main static collider so it doesn't block the player.
	$CollisionShape3D.disabled = true
	
	var item_root = get_parent()
	
	# --- THIS IS THE KEY LOGIC ---
	# First, ask the interactor (the player) how many items it's already holding.
	# We assume the player has a function named 'get_held_item_count()'.
	var current_item_count: int = 0
	if interactor.has_method("get_held_item_count"):
		current_item_count = interactor.get_held_item_count()

	# Define how much vertical space each item takes up.
	var stack_height_offset: float = 0.1 

	# Calculate the vertical position for this new item.
	var vertical_position = current_item_count * stack_height_offset
	# --- END OF KEY LOGIC ---

	# Now, reparent the object into the player's container.
	if item_root and container:
		item_root.get_parent().remove_child(item_root)
		container.add_child(item_root)
		
		# Position the item with the calculated vertical offset and a slight random jitter.
		item_root.position = Vector3(
			randf_range(-0.05, 0.05), # Reduced jitter for more stable stacking
			vertical_position,
			randf_range(-0.05, 0.05)
		)
		item_root.rotation = Vector3.ZERO
		
		# Finally, tell the player to add this item to its list.
		if interactor.has_method("set_held_item"):
			interactor.set_held_item(item_root)
	else:
		get_parent().queue_free()
