class_name Interactable
extends StaticBody3D 
# <-- Note: Changed to StaticBody3D to match your setup.
@export var interaction_prompt: String = "GRAB"

# --- Private Variables ---
var _highlight_component: HighlightComponent

func _ready() -> void:
	# Find the highlight component. We assume it's a child.
	_highlight_component = find_child("HighlightComponent", true, false)
	if not _highlight_component:
		push_warning("Interactable object '%s' has no HighlightComponent child." % self.name)

# --- Public API ---
func highlight() -> void:
	if _highlight_component:
		_highlight_component.apply_highlight()

func unhighlight() -> void:
	if _highlight_component:
		_highlight_component.remove_highlight()

func interact(interactor: Node) -> void:
	print("'%s' was interacted with by '%s'." % [self.name, interactor.name])
	get_parent().queue_free() # Assumes Node3D -> Mesh -> StaticBody. Frees the parent Node3D.
