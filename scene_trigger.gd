class_name SceneTrigger extends Area2D

@export_file("*.tscn") var connected_scene : String

func _on_body_entered(body: Node2D) -> void:
	# 1. Get the full path of the scene we are currently in
	var current_scene_path = get_tree().current_scene.scene_file_path
		
	# 2. Store the player's position keyed by the current scene path
	if current_scene_path == "res://playground.tscn":
		GameManager.scene_positions[current_scene_path] = body.global_position + Vector2(0,20)
		
	# 3. Change scene
	print(connected_scene)
	get_tree().call_deferred("change_scene_to_file", connected_scene)
