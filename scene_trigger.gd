class_name SceneTrigger extends Area2D

@export var connected_scene : String = "playground"#name of the scene to change to
var scene_folder = "res://"

func _on_body_entered(body: Node2D) -> void:
	# 1. Get the full path of the scene we are currently in
	var current_scene_path = get_tree().current_scene.scene_file_path
		
	# 2. Store the player's position keyed by the current scene path
	GameManager.scene_positions[current_scene_path] = body.global_position
		
	# 3. Change scene
	var full_path = scene_folder + connected_scene + ".tscn"
	get_tree().call_deferred("change_scene_to_file", full_path)
