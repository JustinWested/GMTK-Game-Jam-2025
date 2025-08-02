# A reusable component that can apply a highlight effect to any MeshInstance3D.
class_name HighlightComponent
extends Node

# --- Exports ---
# Drag the MeshInstance3D you want this component to affect into this slot.
@export var target_mesh_path: NodePath

# --- Private Variables ---
@onready var _target_mesh: MeshInstance3D = get_node_or_null(target_mesh_path)
var _highlight_material: ShaderMaterial

# Pre-load the shader resource so we don't load it from disk every time.
const HIGHLIGHT_SHADER = preload("res://highlight_shader.gdshader")

func _ready() -> void:

	# Create the shader material instance once and keep it handy.
	_highlight_material = ShaderMaterial.new()
	_highlight_material.shader = HIGHLIGHT_SHADER


# Called by an Interactable to turn the highlight ON.
func apply_highlight() -> void:
	if not is_instance_valid(_target_mesh):
		return

	# Get the mesh's currently active material.
	var original_material = _target_mesh.get_active_material(0)
	if not original_material:
		return

	# This is the magic: get the original texture from the original material.
	var original_texture = original_material.albedo_texture
	
	# Pass that texture to our highlight shader.
	_highlight_material.set_shader_parameter("object_texture", original_texture)
	
	# Apply our custom shader material as an override.
	_target_mesh.material_override = _highlight_material


# Called by an Interactable to turn the highlight OFF.
func remove_highlight() -> void:
	if not is_instance_valid(_target_mesh):
		return
	
	# Simply remove the override to restore the original material.
	_target_mesh.material_override = null
