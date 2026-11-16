extends Node
## Smoke test for the last two villains and their challenges:
## Mildew's pressure purge, Redtape's orthodontic review, the sixth-item
## return-to-clinic nudge, and the clinic cast (Priya visible, Kunal on cue).
## Run with: godot --headless --path . res://tools/test_day7.tscn

const HUB_PATH := "res://playground.tscn"
const CLINIC_PATH := "res://Scenes/Clinic/Clinic.tscn"
const PURGE_PATH := "res://Challenges/pressure_purge.tscn"
const QUIZ_PATH := "res://Challenges/redtape_quiz.tscn"
const FOUR_ITEMS := [&"mirror_set", &"chair", &"curing_light", &"xray"]
const FIVE_ITEMS := [&"mirror_set", &"chair", &"curing_light", &"xray", &"sterilizer"]

var failures: int = 0
var _save_backup: String = ""
var _had_save: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_backup_save()
	await get_tree().process_frame

	await _check_clinic_cast()
	await _check_pressure_purge()
	await _check_redtape_quiz()
	await _check_mildew_encounter()
	await _check_redtape_return_dialog()

	if DialogSystem.is_active:
		DialogSystem.hide_dialog()
	get_tree().paused = false
	_restore_save()
	GameState.load_game()

	print("DAY7 SMOKE: %d failure(s)" % failures)
	get_tree().quit(1 if failures > 0 else 0)


func _check_clinic_cast() -> void:
	GameState.new_game()
	GameState.set_flag("got_notebook", true)
	GameState.set_quest_stage("restore_clinic", 3)
	for item in FOUR_ITEMS:
		GameState.recover_item(item)

	var clinic := await _fresh_clinic()
	var priya := clinic.get_node_or_null("Priya") as Node2D
	var kunal := clinic.get_node_or_null("Kunal") as Node2D
	_check(priya != null and priya.visible, "Priya stands in the clinic")
	if priya != null:
		var sprite := priya.get_node_or_null("Sprite2D") as Sprite2D
		_check(sprite != null and sprite.texture != null, "Priya has a visible world sprite")
		_check(priya.position == Vector2(135, 108),
			"Priya stands clear of the HUD corner")
	_check(kunal != null and not kunal.visible, "Kunal waits offstage before all six are home")

	var kunal_interaction := kunal.get_node_or_null("DialogInteraction") as DialogInteraction
	_check(kunal_interaction != null, "Kunal has a finale conversation")
	_check(kunal_interaction != null and not kunal_interaction.enabled,
		"Kunal's conversation is dormant before the finale")

	GameState.recover_item(&"sterilizer")
	GameState.recover_item(&"records")
	await _wait_frames(3)
	_check(kunal != null and kunal.visible and kunal.is_visible_in_tree(),
		"Kunal appears for reopening day")
	_check(kunal_interaction != null and kunal_interaction.enabled,
		"Kunal's conversation wakes up for the finale")
	await _free_scene(clinic)


func _check_pressure_purge() -> void:
	var purge: PressurePurge = load(PURGE_PATH).instantiate()
	add_child(purge)
	await get_tree().process_frame
	_check(get_tree().paused, "the pressure challenge pauses the world")
	_check(purge.title_label.text == "Pressure Purge", "pressure challenge has its title")
	_check(purge.duration == 24.0, "pressure challenge gives twenty-four seconds")
	_check(purge.catches_needed == 5, "the sterilizer needs five vents")
	_check(purge.max_misses == 2, "two misses end the pressure attempt")
	_check(purge.play_area.get_child_count() >= 6, "the gauge draws a face and a needle")

	for i in 5:
		purge.needle_x = purge.target_x
		purge._try_vent()
	await get_tree().process_frame
	_check(purge.catches == 5, "five vents fill the pressure meter")
	_check(not purge.running, "five vents complete the pressure challenge")
	_check(purge.continue_button.visible, "the pressure challenge shows continue on success")
	purge._on_continue_pressed()
	await get_tree().process_frame
	_check(not get_tree().paused, "finishing the pressure challenge unpauses the world")

	var missed: PressurePurge = load(PURGE_PATH).instantiate()
	add_child(missed)
	await get_tree().process_frame
	missed.needle_x = missed.target_x + 999.0
	missed._try_vent()
	missed._try_vent()
	await get_tree().process_frame
	_check(missed.misses == 2, "each missed vent is counted")
	_check(not missed.running, "two missed vents end the attempt")
	_check(missed.retry_button.visible, "the pressure failure offers a retry")
	missed.queue_free()
	await get_tree().process_frame
	_check(not get_tree().paused, "freeing a failed pressure challenge unpauses the world")


func _check_redtape_quiz() -> void:
	var quiz: RedtapeQuiz = load(QUIZ_PATH).instantiate()
	add_child(quiz)
	await get_tree().process_frame
	_check(get_tree().paused, "the ortho review pauses the world")
	_check(quiz.title_label.text == "Form 27-B", "the ortho review has its title")
	_check(quiz.duration == 40.0, "the ortho review gives forty seconds")
	_check(quiz.question_total() == 5, "Form 27-B has five questions")
	_check(quiz.option_buttons.size() == 4, "each question offers four answers")
	_check(quiz.max_mistakes == 2, "one wrong answer is tolerated")
	_check(quiz.instructions_label.get_theme_font_size("font_size") >= 12,
		"the quiz question is set in readable type")
	_check(quiz.status_label.get_theme_font_size("font_size") >= 10,
		"the quiz status line is set in readable type")
	_check(quiz.option_buttons[0].get_theme_font_size("font_size") >= 11,
		"the quiz answers are set in readable type")

	quiz.answer_delay = 0.0
	for i in 5:
		quiz.choose(quiz.correct_index())
		await get_tree().process_frame
	_check(quiz.correct_count == 5, "five correct answers pass the review")
	_check(not quiz.running, "passing the review completes the challenge")
	_check(quiz.continue_button.visible, "the ortho review shows continue on success")
	quiz._on_continue_pressed()
	await get_tree().process_frame
	_check(not get_tree().paused, "finishing the ortho review unpauses the world")

	var forgiving: RedtapeQuiz = load(QUIZ_PATH).instantiate()
	add_child(forgiving)
	await get_tree().process_frame
	forgiving.answer_delay = 0.0
	forgiving.choose((forgiving.correct_index() + 1) % 4)
	await get_tree().process_frame
	_check(forgiving.mistakes == 1, "a wrong answer is counted")
	_check(forgiving.question_index == 1, "one wrong answer still moves the review on")
	_check(forgiving.running, "one wrong answer does not end the review")
	for i in 4:
		forgiving.choose(forgiving.correct_index())
		await get_tree().process_frame
	_check(not forgiving.running and forgiving.continue_button.visible,
		"one mistake still allows a pass")
	forgiving._on_continue_pressed()
	await get_tree().process_frame

	var failed: RedtapeQuiz = load(QUIZ_PATH).instantiate()
	add_child(failed)
	await get_tree().process_frame
	failed.answer_delay = 0.0
	failed.choose((failed.correct_index() + 1) % 4)
	await get_tree().process_frame
	failed.choose((failed.correct_index() + 1) % 4)
	await get_tree().process_frame
	_check(failed.mistakes == 2, "a second wrong answer is counted")
	_check(not failed.running, "a second wrong answer ends the review")
	_check(failed.retry_button.visible, "the ortho review failure offers a retry")
	failed.queue_free()
	await get_tree().process_frame
	_check(not get_tree().paused, "freeing a failed ortho review unpauses the world")


func _check_mildew_encounter() -> void:
	var hub := await _fresh_hub(FOUR_ITEMS)
	var nook := hub.get_node_or_null("MildewNook") as Node2D
	var mildew: Node = nook.get_node_or_null("Mildew") if nook != null else null
	_check(mildew != null and mildew.visible and mildew._active,
		"Mildew waits beside the well")
	if mildew == null:
		await _free_scene(hub)
		return

	mildew._start_encounter()
	await get_tree().create_timer(0.2).timeout
	_check(DialogSystem.is_active, "Mildew's intro dialog is active")
	_check("sterilizer" in _dialog_text(), "Mildew talks about the sterilizer")
	if DialogSystem.is_active:
		DialogSystem.hide_dialog()
	await _wait_frames(2)

	var challenge: Node = hub.get_node_or_null("PressurePurge")
	_check(challenge != null, "the pressure challenge opens after Mildew's intro")
	if challenge != null:
		for i in 5:
			challenge.needle_x = challenge.target_x
			challenge._try_vent()
		await get_tree().process_frame
		_check(not challenge.running, "five clean vents beat Mildew")
		challenge._on_continue_pressed()
		await _wait_for_dialog()

	_check(GameState.has_item(&"sterilizer"), "the sterilizer is recovered")
	_check(GameState.has_flag("villain_mildew_cleared"), "Mildew's cleared flag is set")
	if DialogSystem.is_active:
		DialogSystem.hide_dialog()
	await _wait_frames(3)
	_check(mildew == null or not is_instance_valid(mildew), "Mildew leaves after victory")
	await _free_scene(hub)


func _check_redtape_return_dialog() -> void:
	var hub := await _fresh_hub(FIVE_ITEMS)
	var cart := hub.get_node_or_null("RecordsCart") as Node2D
	var redtape: Node = cart.get_node_or_null("Redtape") if cart != null else null
	_check(redtape != null and redtape.visible and redtape._active,
		"Redtape waits at the flower shop")
	if redtape == null:
		await _free_scene(hub)
		return

	redtape._start_encounter()
	await get_tree().create_timer(0.2).timeout
	_check(DialogSystem.is_active, "Redtape's intro dialog is active")
	_check("Form 27-B" in _dialog_text(), "Redtape explains Form 27-B")
	if DialogSystem.is_active:
		DialogSystem.hide_dialog()
	await _wait_frames(2)

	var challenge: Node = hub.get_node_or_null("RedtapeQuiz")
	_check(challenge != null, "the ortho review opens after Redtape's intro")
	if challenge != null:
		challenge.answer_delay = 0.0
		for i in 5:
			challenge.choose(challenge.correct_index())
			await get_tree().process_frame
		_check(not challenge.running, "five correct answers beat Redtape")
		challenge._on_continue_pressed()
		await _wait_for_dialog()

	_check(GameState.has_item(&"records"), "the patient records are recovered")
	_check(GameState.has_flag("villain_redtape_cleared"), "Redtape's cleared flag is set")
	_check(_dialog_text().contains("Filed") or _dialog_text().contains("Approved"),
		"Redtape stamps the victory")
	if DialogSystem.is_active:
		DialogSystem.hide_dialog()

	# The sixth recovery should finish the victory lines and then play the
	# player's own thought about heading back to the clinic.
	var prompted := await _wait_for_dialog()
	_check(prompted, "the sixth recovery starts the return-to-clinic dialog")
	var return_text := _dialog_text()
	_check(return_text.begins_with("Hmm, I should head back to the clinic"),
		"the return dialog begins with heading back to the clinic")
	_check("That should be all six." in return_text,
		"the return dialog confirms all six pieces")
	_check(GameState.has_flag("clinic_return_prompted"),
		"the return dialog is only prompted once")
	if DialogSystem.is_active:
		DialogSystem.hide_dialog()
	await _wait_frames(3)
	_check(redtape == null or not is_instance_valid(redtape), "Redtape leaves after victory")
	await _free_scene(hub)


func _fresh_hub(items: Array) -> Node:
	GameState.new_game()
	GameState.set_flag("got_notebook", true)
	GameState.set_quest_stage("restore_clinic", 3)
	for item in items:
		GameState.recover_item(item)
	await get_tree().process_frame
	var hub: Node = load(HUB_PATH).instantiate()
	get_tree().root.add_child(hub)
	get_tree().current_scene = hub
	await _wait_frames(2)
	return hub


func _fresh_clinic() -> Node:
	var clinic: Node = load(CLINIC_PATH).instantiate()
	get_tree().root.add_child(clinic)
	get_tree().current_scene = clinic
	await _wait_frames(2)
	return clinic


func _wait_for_dialog(timeout_frames: int = 240) -> bool:
	for i in timeout_frames:
		if DialogSystem.is_active:
			return true
		await get_tree().process_frame
	return false


func _dialog_text() -> String:
	var text := ""
	if not DialogSystem.is_active:
		return text
	for item in DialogSystem.dialog_items:
		if item is DialogText:
			text += item.text + "\n"
	return text


func _wait_frames(frames: int) -> void:
	for i in frames:
		await get_tree().process_frame


func _free_scene(scene: Node) -> void:
	if DialogSystem.is_active:
		DialogSystem.hide_dialog()
	get_tree().paused = false
	scene.queue_free()
	await get_tree().process_frame
	if get_tree().current_scene == scene:
		get_tree().current_scene = null


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
