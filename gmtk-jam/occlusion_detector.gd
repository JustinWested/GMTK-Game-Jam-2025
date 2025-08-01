# Detects objects between the camera and the player, then tells them
# to become transparent using a shader parameter.
class_name OcclusionDetector
extends ShapeCast3D
@onready var _player: PlayerController = $"../../.."

# --- Private Variables ---

var _last_occluder: MeshInstance3D = null


func _physics_process(_delta: float) -> void:
	# Ensure we have a valid player to target.
	if not is_instance_valid(_player):
		return

	# Update the shapecast's target to point from the camera to the player.
	global_position = get_parent_node_3d().global_position
	target_position = to_local(_player.global_position)
	force_shapecast_update()

	# Case 1: The shapecast hit something.
	if is_colliding():
		# Get the first object we hit. This is the corrected line.
		var current_occluder = get_collider(0) as MeshInstance3D
		
		# If we hit a valid mesh...
		if current_occluder:
			# ...and it's a different mesh than the last one...
			if current_occluder != _last_occluder:
				# ...restore the old one before fading the new one.
				_restore_previous_occluder()
				_fade_occluder(current_occluder)
				_last_occluder = current_occluder
		# If we hit something that's not a mesh (e.g. another physics body),
		# treat it as if we hit nothing.
		else:
			_restore_previous_occluder()
			_last_occluder = null

	# Case 2: The shapecast hit nothing.
	else:
		_restore_previous_occluder()
		_last_occluder = null



### Private Functions ###

# Fades an object by setting its material's shader parameter.
func _fade_occluder(occluder: MeshInstance3D) -> void:
	# Ensure the occluder has a material we can modify.
	var material = occluder.get_active_material(0)
	if material is ShaderMaterial:
		material.set_shader_parameter("fade_alpha", 0.2)


# Restores the last-faded object to full opacity.
func _restore_previous_occluder() -> void:
	if is_instance_valid(_last_occluder):
		var material = _last_occluder.get_active_material(0)
		if material is ShaderMaterial:
			material.set_shader_parameter("fade_alpha", 1.0)
