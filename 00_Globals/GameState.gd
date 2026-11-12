extends Node
## Global game state for The Great Clinic Robbery.
##
## Owns quest flags, quest stages, recovered clinic items, collected stickers
## and per-scene player positions. Everything is persisted to user://save.json
## so progress survives quitting the game.
##
## This replaces the old GameManager autoload. The old script is kept on disk
## for reference but is no longer registered.

signal flag_changed(flag: String, value)
signal item_recovered(item_id: String)
signal quest_stage_changed(quest_id: String, stage: int)
signal game_loaded

const SAVE_PATH := "user://save.json"
const SAVE_VERSION := 1
const DEFAULT_QUEST_STAGES := {"restore_clinic": 0}

var flags: Dictionary = {}
var quest_stages: Dictionary = DEFAULT_QUEST_STAGES.duplicate()
var recovered_items: Array = []
var stickers: Array = []
## Key: scene path (e.g. "res://playground.tscn"), value: Vector2.
var scene_positions: Dictionary = {}
## Scene the player was in when the game was last saved.
var last_scene: String = ""
## True when a readable save file exists (or one was just written).
var save_available: bool = false

var _loading: bool = false


func _ready() -> void:
	save_available = load_game()


func _notification(what: int) -> void:
	# Save the exact spot when the player closes the window.
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_current_scene_state()


# --- Flags -----------------------------------------------------------------

func set_flag(flag: String, value: Variant = true) -> void:
	if flag.is_empty():
		return
	flags[flag] = value
	flag_changed.emit(flag, value)
	save_game()


func has_flag(flag: String) -> bool:
	return flags.get(flag, false) == true


func get_flag(flag: String, default_value: Variant = false) -> Variant:
	return flags.get(flag, default_value)


func clear_flag(flag: String) -> void:
	if not flags.has(flag):
		return
	flags.erase(flag)
	flag_changed.emit(flag, false)
	save_game()


# --- Recovered items -------------------------------------------------------

func recover_item(item_id: String) -> void:
	if item_id.is_empty() or item_id in recovered_items:
		return
	recovered_items.append(item_id)
	item_recovered.emit(item_id)
	save_game()


func has_item(item_id: String) -> bool:
	return item_id in recovered_items


func recovered_count() -> int:
	return recovered_items.size()


# --- Quest stages ----------------------------------------------------------

## Stages only move forward, so a repeated or out-of-order trigger is harmless.
func set_quest_stage(quest_id: String, stage: int) -> void:
	if stage <= int(quest_stages.get(quest_id, 0)):
		return
	quest_stages[quest_id] = stage
	quest_stage_changed.emit(quest_id, stage)
	save_game()


func get_quest_stage(quest_id: String) -> int:
	return int(quest_stages.get(quest_id, 0))


# --- Stickers --------------------------------------------------------------

func add_sticker(sticker_id: String) -> void:
	if sticker_id.is_empty() or sticker_id in stickers:
		return
	stickers.append(sticker_id)
	save_game()


func has_sticker(sticker_id: String) -> bool:
	return sticker_id in stickers


# --- Per-scene player positions -------------------------------------------

func set_scene_position(scene_path: String, position: Vector2) -> void:
	if scene_path.is_empty():
		return
	scene_positions[scene_path] = position
	save_game()


func get_scene_position(scene_path: String) -> Variant:
	return scene_positions.get(scene_path)


func has_scene_position(scene_path: String) -> bool:
	return scene_positions.has(scene_path)


## Record the scene the player is currently in so Continue can resume there.
func set_last_scene(path: String) -> void:
	if path.is_empty() or path == last_scene:
		return
	last_scene = path
	save_game()


func get_last_scene() -> String:
	return last_scene


## Save the current scene and the player's exact position. Used when the game
## closes or when the player returns to the main menu.
func save_current_scene_state() -> void:
	var scene := get_tree().current_scene
	if scene == null or scene.scene_file_path.is_empty():
		return
	var player := scene.find_child("Player", true, false)
	if not (player is Node2D):
		return
	scene_positions[scene.scene_file_path] = (player as Node2D).global_position
	last_scene = scene.scene_file_path
	save_game()


func has_save() -> bool:
	return save_available


# --- Save / load -----------------------------------------------------------

func save_game() -> void:
	if _loading:
		return
	var positions := {}
	for path in scene_positions:
		var p: Vector2 = scene_positions[path]
		positions[path] = [p.x, p.y]
	var data := {
		"version": SAVE_VERSION,
		"flags": flags,
		"quest_stages": quest_stages,
		"recovered_items": recovered_items,
		"stickers": stickers,
		"scene_positions": positions,
		"last_scene": last_scene,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("GameState: could not write %s" % SAVE_PATH)
		return
	file.store_string(JSON.stringify(data))
	file.close()
	save_available = true


func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		save_available = false
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("GameState: save file is not valid JSON, ignoring it")
		save_available = false
		return false

	_loading = true
	flags = parsed.get("flags", {})
	quest_stages = parsed.get("quest_stages", DEFAULT_QUEST_STAGES.duplicate())
	recovered_items = parsed.get("recovered_items", [])
	stickers = parsed.get("stickers", [])
	last_scene = parsed.get("last_scene", "")

	scene_positions.clear()
	var positions: Dictionary = parsed.get("scene_positions", {})
	for path in positions:
		var value = positions[path]
		if typeof(value) == TYPE_ARRAY and value.size() >= 2:
			scene_positions[path] = Vector2(float(value[0]), float(value[1]))
	_loading = false
	save_available = true

	game_loaded.emit()
	return true


func new_game() -> void:
	flags.clear()
	quest_stages = DEFAULT_QUEST_STAGES.duplicate()
	recovered_items.clear()
	stickers.clear()
	scene_positions.clear()
	last_scene = ""
	_loading = false
	save_game()
