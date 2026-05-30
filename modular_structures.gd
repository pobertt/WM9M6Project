@tool
extends Node3D

@export var rebuild_all_structures: bool = false:
	set(value):
		if value:
			_unpack_with_structure()
		rebuild_all_structures = false

func _unpack_with_structure() -> void:
	var count = 0
	var instances_to_delete = []
	
	for instance in get_children():
		var found_meshes = _find_all_meshes(instance)
		
		if found_meshes.size() > 0:
			
			# --- THE FIX: Steal the name and rename the old wrapper! ---
			var original_name = instance.name
			instance.name = original_name + "_garbage"
			
			var clean_parent = Node3D.new()
			# Now Godot will accept the original name without panicking
			clean_parent.name = original_name 
			clean_parent.global_transform = instance.global_transform
			
			add_child(clean_parent)
			clean_parent.owner = get_tree().edited_scene_root
			
			for m in found_meshes:
				var clean_mesh = MeshInstance3D.new()
				clean_mesh.mesh = m.mesh
				clean_mesh.name = m.name 
				
				clean_parent.add_child(clean_mesh)
				clean_mesh.owner = get_tree().edited_scene_root
				clean_mesh.global_transform = m.global_transform 
				
			print("Rebuilt exact structure for: ", clean_parent.name)
			count += 1
			instances_to_delete.append(instance)

	for old_instance in instances_to_delete:
		old_instance.queue_free()
					
	print("--- FINISHED! Successfully rebuilt ", count, " perfectly named folders! ---")

func _find_all_meshes(node: Node) -> Array:
	var result = []
	if node is MeshInstance3D and node.mesh != null:
		result.append(node)
		
	for child in node.get_children(true):
		result.append_array(_find_all_meshes(child))
		
	return result
