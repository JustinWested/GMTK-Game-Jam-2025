# A simple, runnable scanner. This version correctly identifies nodes by their class.
extends Node

@export var scene_to_scan: PackedScene

func _ready() -> void:
	print("--- SCANNING FOR BROKEN INTERACTABLES ---")
	
	if not scene_to_scan:
		print("ERROR: 'Scene To Scan' is not set in the Inspector.")
		get_tree().quit()
		return

	var scene_instance = scene_to_scan.instantiate()
	
	# Start the recursive scan.
	_find_faulty_components(scene_instance)
	
	print("--- SCAN COMPLETE ---")
	get_tree().quit()


# The recursive search function with the corrected detection logic.
func _find_faulty_components(node: Node) -> void:
	# THE FIX: We check the node's class directly using 'is'.
	# This works instantly and doesn't rely on _ready() or groups.
	if node is HighlightComponent:
		var component = node
		var target_path = component.get("target_mesh_path") as NodePath
		
		if target_path.is_empty():
			print("BROKEN: %s -> Target Mesh Path is empty." % _get_full_path(component, get_parent()))
		else:
			var target_node = component.get_node_or_null(target_path)
			if not target_node:
				print("BROKEN: %s -> Target mesh path is broken." % _get_full_path(component, get_parent()))
			elif not target_node is MeshInstance3D:
				var node_type = target_node.get_class()
				print("BROKEN: %s -> Target is a '%s', but must be a MeshInstance3D." % [_get_full_path(component, get_parent()), node_type])

	for child in node.get_children():
		_find_faulty_components(child)


# Helper function to reconstruct a useful path for debugging.
func _get_full_path(node: Node, root: Node) -> String:
	# This function had a bug, it should check against the instance root, not get_parent()
	if node == root or not node.get_parent():
		return node.name
	return _get_full_path(node.get_parent(), root) + "/" + node.name
