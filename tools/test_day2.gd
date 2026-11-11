extends Node
## Temporary smoke test for the Day 2 clinic vertical slice.
## Run with: godot --headless --path . res://tools/test_day2.tscn

var failures: int = 0
var _save_backup: String = ""
var _had_save: bool = false


func _ready() -> void:
	await get_tree().process_frame
	_check(ItemCatalog.TOTAL == 6, "ItemCatalog has six items")

	# Never clobber a real player save when this test runs.
	_backup_save()
	GameState.new_game()
	SceneRouter.next_spawn = &"clinic_door"
	var clinic: Node = load("res://Scenes/Clinic/Clinic.tscn").instantiate()
	get_tree().root.add_child(clinic)
	get_tree().current_scene = clinic
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	var player := clinic.get_node_or_null("Player")
	_check(player != null, "player exists in the clinic")
	if player != null:
		_check(player.global_position.distance_to(Vector2(241, 205)) < 2.0, "clinic_door spawn marker used")
	_check(get_tree().current_scene == clinic, "spawning near the door does not re-trigger the exit")

	var priya := clinic.get_node_or_null("Priya")
	var mehta := clinic.get_node_or_null("Mehta")
	var blorb := clinic.get_node_or_null("Blorb")
	var shelf := clinic.get_node_or_null("ItemShelf")
	_check(priya != null, "Priya exists in the clinic")
	_check(mehta != null, "Mr. Mehta exists in the clinic")
	_check(blorb != null, "Blorb exists in the clinic")
	_check(shelf != null, "Item shelf exists in the clinic")
	_check(clinic.get_node_or_null("clinic_door") != null, "clinic_door spawn marker exists")
	_check(not GameHUD.root.visible, "HUD is hidden before the quest starts")

	# Priya auto-greets the player shortly after arrival.
	await get_tree().create_timer(2.0).timeout
	_check(DialogSystem.is_active, "Priya auto-greet dialog is active")
	_check(not player.input_enabled, "player movement locked during dialog")
	if DialogSystem.is_active:
		DialogSystem.hide_dialog()
		await get_tree().process_frame
	await get_tree().process_frame
	_check(player.input_enabled, "player movement restored after dialog")
	_check(GameState.has_flag("met_clerk"), "met_clerk flag set after intro")
	_check(GameState.has_flag("got_notebook"), "notebook granted after intro")
	_check(GameState.has_flag("got_toothbrush"), "toothbrush granted after intro")
	_check(GameState.get_quest_stage("restore_clinic") == 2, "quest stage advanced to 2")

	# HUD and notebook.
	_check(GameHUD.root.visible, "HUD visible inside the clinic")
	GameHUD.open_notebook()
	await get_tree().process_frame
	_check(GameHUD.notebook.visible, "notebook opens")
	_check(get_tree().paused, "notebook pauses the world")
	GameHUD.close_notebook()
	await get_tree().process_frame
	_check(not get_tree().paused, "closing the notebook unpauses")

	# Blorb encounter end to end.
	_check(blorb.data.guarded_item_id == &"mirror_set", "Blorb guards the mirror set")
	blorb._start_encounter()
	await get_tree().create_timer(0.2).timeout
	_check(DialogSystem.is_active, "Blorb intro dialog is active")
	if DialogSystem.is_active:
		DialogSystem.hide_dialog()
	await get_tree().process_frame
	await get_tree().process_frame

	var challenge: Node = clinic.get_node_or_null("BrushOff")
	_check(challenge != null, "brush challenge opened")
	if challenge != null:
		_check(get_tree().paused, "challenge pauses the world")
		for i in 40:
			var event := InputEventAction.new()
			event.action = "hit"
			event.pressed = true
			challenge._unhandled_input(event)
		await get_tree().process_frame
		_check(not challenge.running, "brushing completes the challenge")
		challenge._on_continue_pressed()
		await get_tree().process_frame

	_check(GameState.has_item(&"mirror_set"), "mirror set recovered")
	_check(GameState.get_quest_stage("restore_clinic") == 3, "quest stage advanced to 3")
	_check(GameState.has_flag("villain_blorb_cleared"), "blorb cleared flag set")
	if DialogSystem.is_active:
		DialogSystem.hide_dialog()
	await get_tree().process_frame
	await get_tree().process_frame
	_check(not is_instance_valid(blorb), "Blorb leaves after victory")
	_check("1 / 6" in GameHUD.counter_label.text, "HUD counter shows 1 / 6")

	# Skip is offered after three failed attempts and still advances the quest.
	var solo: Node = load("res://Challenges/brush_off.tscn").instantiate()
	clinic.add_child(solo)
	await get_tree().process_frame
	await get_tree().process_frame
	solo.fail()
	solo._on_retry_pressed()
	solo.fail()
	solo._on_retry_pressed()
	solo.fail()
	await get_tree().process_frame
	_check(solo.skip_button.visible, "skip offered after three failed attempts")
	solo._on_skip_pressed()
	await get_tree().process_frame
	_check(not is_instance_valid(solo), "skipping closes the challenge")
	_check(not get_tree().paused, "skipping unpauses the world")

	print("DAY2 SMOKE: %d failure(s)" % failures)
	get_tree().quit(1 if failures > 0 else 0)


func _check(condition: bool, label: String) -> void:
	if condition:
		print("  ok   ", label)
	else:
		failures += 1
		print("  FAIL ", label)


func _backup_save() -> void:
	_had_save = FileAccess.file_exists(GameState.SAVE_PATH)
	if not _had_save:
		return
	var file := FileAccess.open(GameState.SAVE_PATH, FileAccess.READ)
	if file != null:
		_save_backup = file.get_as_text()
		file.close()


func _restore_save() -> void:
	if _had_save and not _save_backup.is_empty():
		var file := FileAccess.open(GameState.SAVE_PATH, FileAccess.WRITE)
		if file != null:
			file.store_string(_save_backup)
			file.close()
	elif not _had_save and FileAccess.file_exists(GameState.SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(GameState.SAVE_PATH))


func _exit_tree() -> void:
	_restore_save()
