class_name SceneTrigger extends Area2D

## Raw scene path or UID. Kept so existing triggers keep working unchanged.
@export_file("*.tscn") var connected_scene : String
## Preferred: a named destination from SceneRouter (e.g. "clinic").
@export var destination : String = ""
## Optional spawn marker the destination scene should place the player at.
@export var spawn_point : StringName = &""

func _on_body_entered(body: Node2D) -> void:
	# Remember where the player left the hub so they return to the same spot.
	var current_scene_path = get_tree().current_scene.scene_file_path
	if current_scene_path == "res://playground.tscn":
		GameState.set_scene_position(current_scene_path, body.global_position + Vector2(0, 20))

	# Change scene through the router so spawn points are carried across.
	if destination != "":
		SceneRouter.go(destination, spawn_point)
	elif connected_scene != "":
		SceneRouter.go_to_path(connected_scene, spawn_point)
