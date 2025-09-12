class_name SceneTrigger extends Area2D

@export var connected_scene : String #name of the scene to change to
var scene_folder = "res://Scenes/Badminton/"

func _on_body_entered(body: Node2D) -> void:
	var full_path = scene_folder + connected_scene + ".tscn"
	var scene_tree = get_tree()
	scene_tree.call_deferred("change_scene_to_file",full_path)
	pass # Replace with function body.
