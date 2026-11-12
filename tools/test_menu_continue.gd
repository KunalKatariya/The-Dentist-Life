extends Node
## Smoke test for Start / Continue and Priya's dialog in both cases.
## Run with: godot --headless --path . res://tools/test_menu_continue.tscn

const CLINIC_PATH := "res://Scenes/Clinic/Clinic.tscn"

var failures: int = 0
var _save_backup: String = ""
var _had_save: bool = false
var _clinic: Node = null


func _ready() -> void:
	await get_tree().process_frame
	_backup_save()

	_test_new_game_resets_progress()
	await _test_continue_restores_progress()
	await _test_new_game_priya_dialog()
	await _test_main_menu_continue_state()
	await _test_menu_button_flow()

	print("MENU CONTINUE SMOKE: %d failure(s)" % failures)
	get_tree().quit(1 if failures > 0 else 0)


# --- Tests -----------------------------------------------------------------

func _test_new_game_resets_progress() -> void:
	GameState.new_game()
	GameState.set_flag("met_clerk", true)
	GameState.recover_item("mirror_set")
	GameState.set_quest_stage("restore_clinic", 3)
	GameState.set_last_scene(CLINIC_PATH)
	GameState.save_game()
	_check(GameState.has_save(), "seeded save is available")
	_check(GameState.has_item(&"mirror_set"), "seed contains the mirror set")

	GameState.new_game()
	_check(GameState.flags.is_empty(), "new game clears flags")
	_check(GameState.recovered_items.is_empty(), "new game clears recovered items")
	_check(GameState.get_quest_stage("restore_clinic") == 0, "new game resets quest stage")
	_check(GameState.get_last_scene().is_empty(), "new game clears the resume scene")
	_check(GameState.has_save(), "new game writes a fresh save")


func _test_continue_restores_progress() -> void:
	# Seed a mid-quest save, then wipe memory to mimic a fresh launch.
	GameState.new_game()
	GameState.set_flag("met_clerk", true)
	GameState.set_flag("got_notebook", true)
	GameState.set_flag("got_toothbrush", true)
	GameState.set_flag("villain_blorb_cleared", true)
	GameState.recover_item(&"mirror_set")
	GameState.set_quest_stage("restore_clinic", 3)
	GameState.set_last_scene(CLINIC_PATH)
	GameState.set_scene_position(CLINIC_PATH, Vector2(200, 180))
	GameState.flags.clear()
	GameState.recovered_items.clear()
	GameState.quest_stages = GameState.DEFAULT_QUEST_STAGES.duplicate()
	GameState.last_scene = ""
	GameState.scene_positions.clear()

	_check(GameState.load_game(), "Continue loads the save file")
	_check(GameState.has_item(&"mirror_set"), "Continue restores the mirror set")
	_check(GameState.has_flag("met_clerk"), "Continue restores met_clerk")
	_check(GameState.get_quest_stage("restore_clinic") == 3, "Continue restores quest stage 3")
	_check(GameState.get_last_scene() == CLINIC_PATH, "Continue restores the clinic scene")
	_check(GameState.get_scene_position(CLINIC_PATH) == Vector2(200, 180), "Continue restores the player position")

	await _spawn_clinic(&"")
	_check(_clinic != null, "continued game spawns the clinic")
	var player := _clinic.get_node_or_null("Player")
	_check(player != null and player.global_position.distance_to(Vector2(200, 180)) < 2.0, "continued player uses the saved position")
	_check(_clinic.get_node_or_null("Blorb") == null, "Blorb stays gone after Continue")
	_check(GameHUD.root.visible, "HUD visible after Continue")
	_check("1 / 6" in GameHUD.counter_label.text, "Continue shows 1 / 6 equipment")

	# Priya should not re-run the first-time greeting.
	await get_tree().create_timer(2.0).timeout
	_check(not DialogSystem.is_active, "Continue does not replay Priya's first-time greeting")

	var priya := _clinic.get_node_or_null("Priya")
	_check(priya != null, "Priya exists after Continue")
	if priya != null:
		var interaction := priya.get_node_or_null("DialogInteraction")
		interaction.player_interact()
		await get_tree().process_frame
		await get_tree().process_frame
		_check(DialogSystem.is_active, "Priya dialog opens after Continue")
		_check("One down!" in _first_line(), "Priya uses the post-mirror dialog after Continue")
		var presses := await _press_through_dialog()
		_check(presses < 60, "Priya dialog advances with E after Continue")
		_check(not DialogSystem.is_active, "Priya dialog closes after Continue")
		await get_tree().create_timer(0.2).timeout
		_check(not DialogSystem.is_active, "Priya dialog does not reopen after Continue")
		_check(GameState.get_quest_stage("restore_clinic") == 3, "Continue keeps quest stage 3")

	await _free_clinic()


func _test_new_game_priya_dialog() -> void:
	GameState.new_game()
	await _spawn_clinic(&"clinic_door")
	_check(_clinic != null, "new game spawns the clinic")

	var player := _clinic.get_node_or_null("Player")
	_check(player != null and player.global_position.distance_to(Vector2(241, 205)) < 2.0, "new game uses the clinic_door spawn")
	_check(not GameHUD.root.visible, "HUD hidden before the new-game greeting")

	# Priya auto-greets on a fresh game.
	await get_tree().create_timer(2.0).timeout
	_check(DialogSystem.is_active, "new game plays Priya's first-time greeting")
	_check("Doctor! Thank god." in _first_line(), "Priya uses the first-time dialog on a new game")
	var presses := await _press_through_dialog()
	await get_tree().process_frame
	await get_tree().process_frame
	_check(presses < 60, "Priya's first-time dialog advances with E")
	_check(not DialogSystem.is_active, "Priya's first-time dialog closes")
	await get_tree().create_timer(0.2).timeout
	_check(not DialogSystem.is_active, "Priya's first-time dialog does not reopen")
	_check(player.input_enabled, "player movement returns after the greeting")
	_check(GameState.has_flag("met_clerk"), "new game sets met_clerk")
	_check(GameState.has_flag("got_notebook"), "new game grants the notebook")
	_check(GameState.has_flag("got_toothbrush"), "new game grants the toothbrush")
	_check(GameState.get_quest_stage("restore_clinic") == 2, "new game reaches quest stage 2")
	_check(GameHUD.root.visible, "HUD visible after the new-game greeting")
	_check("0 / 6" in GameHUD.counter_label.text, "new game starts at 0 / 6")

	# Talking again before recovering anything gives the repeat dialog.
	var priya := _clinic.get_node_or_null("Priya")
	if priya != null:
		var interaction := priya.get_node_or_null("DialogInteraction")
		interaction.player_interact()
		await get_tree().process_frame
		await get_tree().process_frame
		_check("Any luck?" in _first_line(), "Priya uses the repeat dialog before the mirror is found")
		await _press_through_dialog()

	await _free_clinic()


func _test_main_menu_continue_state() -> void:
	GameState.new_game()
	var menu: Node = load("res://Scenes/MainMenu/main_menu.tscn").instantiate()
	get_tree().root.add_child(menu)
	get_tree().current_scene = menu
	await get_tree().process_frame
	await get_tree().process_frame
	var continue_button := menu.get_node_or_null("Buttons_Manager/ContinueButton")
	_check(continue_button != null, "main menu has a Continue button")
	if continue_button != null:
		_check(not continue_button.disabled, "Continue is enabled when a save exists")
		continue_button.emit_signal("pressed")
		_check(menu.button_type == "continue", "Continue button is wired to the fade-out flow")
		menu.button_type = null
		menu.anim_player.stop()

	# Remove the file and refresh the menu to mimic a first-ever launch.
	DirAccess.remove_absolute(ProjectSettings.globalize_path(GameState.SAVE_PATH))
	GameState.save_available = false
	menu._update_continue_button()
	_check(continue_button.disabled, "Continue is disabled when no save exists")
	continue_button.emit_signal("pressed")
	_check(menu.button_type == null, "Disabled Continue cannot start a game")
	get_tree().current_scene = null
	menu.queue_free()
	await get_tree().process_frame


func _test_menu_button_flow() -> void:
	# Continue: seed a mid-quest save, then use the menu helper exactly as the
	# Continue button does after its fade-out.
	GameState.new_game()
	GameState.set_flag("met_clerk", true)
	GameState.set_flag("got_notebook", true)
	GameState.recover_item(&"mirror_set")
	GameState.set_quest_stage("restore_clinic", 3)
	GameState.set_last_scene(CLINIC_PATH)
	GameState.set_scene_position(CLINIC_PATH, Vector2(200, 180))
	await _swap_to_menu()
	var menu := get_tree().current_scene
	_check(menu != null and menu.has_method("_continue_game"), "menu scene is current before Continue")
	if menu != null:
		menu._continue_game()
	await _wait_for_scene(CLINIC_PATH)
	var scene := get_tree().current_scene
	_check(scene != null and scene.scene_file_path == CLINIC_PATH, "Continue opens the saved clinic scene")
	_check(GameState.has_item(&"mirror_set"), "Continue keeps progress after opening the scene")
	_check(scene != null and "1 / 6" in GameHUD.counter_label.text, "Continue scene shows 1 / 6 equipment")

	# Start: from the menu again, a new game must wipe the old save and land in
	# the hub.
	await _swap_to_menu()
	var menu2 := get_tree().current_scene
	_check(menu2 != null and menu2.has_method("_start_new_game"), "menu scene is current before Start")
	if menu2 != null:
		menu2._start_new_game()
	await _wait_for_scene("res://playground.tscn")
	var hub := get_tree().current_scene
	_check(hub != null and hub.scene_file_path == "res://playground.tscn", "Start opens the hub")
	_check(GameState.flags.is_empty(), "Start clears old flags")
	_check(GameState.recovered_items.is_empty(), "Start clears old equipment")
	_check(GameState.get_quest_stage("restore_clinic") == 0, "Start resets the quest stage")
	_check(GameState.get_last_scene() == "res://playground.tscn", "Start records the hub as the resume scene")
	await _free_current_scene()


# --- Helpers ---------------------------------------------------------------

func _swap_to_menu() -> void:
	await _free_current_scene()
	var menu: Node = load("res://Scenes/MainMenu/main_menu.tscn").instantiate()
	get_tree().root.add_child(menu)
	get_tree().current_scene = menu
	await get_tree().process_frame
	await get_tree().process_frame


func _free_current_scene() -> void:
	var scene := get_tree().current_scene
	if scene != null and is_instance_valid(scene):
		get_tree().current_scene = null
		scene.queue_free()
		await get_tree().process_frame
		await get_tree().process_frame


func _wait_for_scene(path: String) -> void:
	for i in 30:
		await get_tree().process_frame
		var scene := get_tree().current_scene
		if scene != null and is_instance_valid(scene) and scene.scene_file_path == path:
			return

func _spawn_clinic(spawn: StringName) -> void:
	await _free_clinic()
	SceneRouter.clear_spawn()
	if spawn != &"":
		SceneRouter.next_spawn = spawn
	_clinic = load(CLINIC_PATH).instantiate()
	get_tree().root.add_child(_clinic)
	get_tree().current_scene = _clinic
	for i in 5:
		await get_tree().process_frame


func _free_clinic() -> void:
	if DialogSystem.is_active:
		DialogSystem.hide_dialog()
		await get_tree().process_frame
	if _clinic != null and is_instance_valid(_clinic):
		if get_tree().current_scene == _clinic:
			get_tree().current_scene = null
		_clinic.queue_free()
		await get_tree().process_frame
		await get_tree().process_frame
	_clinic = null


func _first_line() -> String:
	if DialogSystem.dialog_items.is_empty():
		return ""
	var item = DialogSystem.dialog_items[0]
	if item is DialogText:
		return (item as DialogText).text
	return ""


func _press_through_dialog() -> int:
	var presses := 0
	while DialogSystem.is_active and presses < 60:
		_push_interact()
		presses += 1
		await get_tree().process_frame
		await get_tree().process_frame
	return presses


func _push_interact() -> void:
	var press := InputEventAction.new()
	press.action = "interact"
	press.pressed = true
	Input.parse_input_event(press)
	var release := InputEventAction.new()
	release.action = "interact"
	release.pressed = false
	Input.parse_input_event(release)


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
