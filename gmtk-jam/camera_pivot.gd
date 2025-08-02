
class_name CameraPivot
extends Node3D

# --- Exports ---
@export var sensitivity: float = 600

@export var player: Node3D
@export var fade_speed: float = 5.0
@export var original_fade_distance: float = 50.0

@onready var raycast: RayCast3D = $RayCast3D
@onready var camera: Camera3D = $SpringArm3D/BaseCamera


var managed_objects = {}


func _ready() -> void:
	# Lock and hide the cursor for direct camera control.
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	if event is InputEventMouseMotion:
		rotation.y -= event.relative.x / sensitivity
		rotation.x -= event.relative.y / sensitivity
		rotation.x = clamp(rotation.x, deg_to_rad(-55), deg_to_rad(38))
		
		
func get_fade_material(node: Node) -> Material:
	# Case 1: The node is a CSG shape. Get its material directly.
	if node is CSGShape3D:
		return node.material

	# Case 2: The node is a physics body. Find its MeshInstance3D child.
	if node is CollisionObject3D:
		for child in node.get_children():
			if child is MeshInstance3D:
				# Return the override material for the first surface.
				return child.get_surface_override_material(0)
	
	# If we can't find a material, return null.
	return null
	
		
func _physics_process(delta: float) -> void:
	if not player:
		return

	# STEP 1: DETECT what object should be faded.
	var obstructed_collider = null
	raycast.force_raycast_update()

	if raycast.is_colliding():
		var collider = raycast.get_collider()
		if collider and collider.is_in_group("fadeable"):
			obstructed_collider = collider

	# STEP 2: UPDATE THE TARGETS for all managed objects.
	if obstructed_collider:
		managed_objects[obstructed_collider] = original_fade_distance

	for object_parent in managed_objects.keys():
		if object_parent != obstructed_collider:
			managed_objects[object_parent] = 0.0

	# STEP 3: APPLY THE LERP using our new helper function.
	for object_parent in managed_objects.keys().duplicate():
		
		var material = get_fade_material(object_parent)

		# If we couldn't find a material for this object, skip it.
		if not material:
			continue

		var current_dist = material.distance_fade_max_distance
		var target_dist = managed_objects[object_parent]

		var new_dist = lerp(current_dist, target_dist, fade_speed * delta)
		material.distance_fade_max_distance = new_dist

		if is_equal_approx(new_dist, 0.0) and target_dist == 0.0:
			managed_objects.erase(object_parent)
