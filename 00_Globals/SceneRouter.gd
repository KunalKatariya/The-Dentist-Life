extends Node
## Named scene destinations and the spawn point to use on arrival.
##
## Scenes must not hard-code scene paths. Ask SceneRouter for a named
## destination instead. A scene that owns a spawn point calls
## SceneRouter.go("clinic", &"clinic_door"); the player then looks for a
## Node2D in the "spawn_points" group named "clinic_door".

signal destination_changed(destination: String)

const SCENES := {
	"menu": "res://Scenes/MainMenu/main_menu.tscn",
	"hub": "res://playground.tscn",
	"clinic": "res://Scenes/Clinic/Clinic.tscn",
	"badminton": "res://Scenes/Badminton/badminton_game.tscn",
	"surprise": "res://Scenes/Surprise/Surprise.tscn",
	"chat": "res://Scenes/AIChat/AIChat.tscn",
}

## Consumed by Player when the next scene loads.
var next_spawn: StringName = &""


func go(destination: String, spawn: StringName = &"") -> void:
	if not SCENES.has(destination):
		push_error("SceneRouter: unknown destination '%s'" % destination)
		return
	go_to_path(SCENES[destination], spawn)


## Used by SceneTrigger, which stores raw scene paths or UIDs.
func go_to_path(path: String, spawn: StringName = &"") -> void:
	if path.is_empty():
		push_error("SceneRouter: empty scene path")
		return
	next_spawn = spawn
	destination_changed.emit(path)
	get_tree().call_deferred("change_scene_to_file", path)


## Returns the requested spawn name once and clears it.
func consume_spawn() -> StringName:
	var spawn := next_spawn
	next_spawn = &""
	return spawn


func clear_spawn() -> void:
	next_spawn = &""
