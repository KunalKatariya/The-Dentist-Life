extends Node
## Smoke test for the Day 3 bakery slice: Wobble, the chair-balance challenge,
## the bakery cart in the hub and Kunal's progress hint.
## Run with: godot --headless --path . res://tools/test_day3.tscn

const HUB_PATH := "res://playground.tscn"
const CLINIC_PATH := "res://Scenes/Clinic/Clinic.tscn"
const CHALLENGE_PATH := "res://Challenges/chair_balance.tscn"

var failures: int = 0
var _save_backup: String = ""
var _had_save: bool = false


func _ready() -> void:
	_backup_save()
	await get_tree().process_frame

	_check_art()
	_check_resources()
	await _check_priya_grants_notebook()
	await _check_hub_and_encounter()
	await _check_challenge_retry_and_skip()
	await _check_repeat_dialog()

	# Restore the player save before quitting. Relying only on _exit_tree has
	# been flaky in headless runs, and this test starts a fresh game.
	_restore_save()
	GameState.load_game()

	print("DAY3 SMOKE: %d failure(s)" % failures)
	get_tree().quit(1 if failures > 0 else 0)


func _check_art() -> void:
	var wobble: Texture2D = load("res://Assets_Imported/villains/wobble.png")
	var portrait: Texture2D = load("res://Assets_Imported/villains/wobble_portrait.png")
	var cart: Texture2D = load("res://Assets_Imported/town/bakery_cart.png")
	_check(wobble != null and wobble.get_width() == 64 and wobble.get_height() == 64,
		"Wobble world sprite is 64x64")
	_check(portrait != null and portrait.get_width() == 400 and portrait.get_height() == 148,
		"Wobble portrait is four 100x148 frames")
	_check(cart != null and cart.get_width() == 64 and cart.get_height() == 48,
		"bakery cart sprite is 64x48")


func _check_resources() -> void:
	var wobble_data: VillainResource = load("res://Data/villains/wobble.tres")
	_check(wobble_data != null, "Wobble villain resource loads")
	if wobble_data != null:
		_check(wobble_data.guarded_item_id == &"chair", "Wobble guards the dental chair")
		_check(wobble_data.challenge_scene != null, "Wobble has a challenge scene")
		_check(wobble_data.npc_info != null and wobble_data.npc_info.portrait != null,
			"Wobble has a portrait for dialog")


func _check_hub_and_encounter() -> void:
	# A save can reach the village without finishing Priya's intro. Nothing in
	# the equipment hunt should wake up until she hands over the notebook.
	GameState.new_game()
	GameState.set_flag("met_clerk", true)

	var hub: Node = load(HUB_PATH).instantiate()
	get_tree().root.add_child(hub)
	get_tree().current_scene = hub
	await get_tree().process_frame
	await get_tree().process_frame

	var bakery: Node = hub.get_node_or_null("BakeryCart")
	_check(bakery != null, "bakery cart is in the hub")
	if bakery == null:
		hub.queue_free()
		return
	_check(bakery.position == Vector2(1540, 130), "bakery cart sits by the clinic")

	var cart := bakery.get_node_or_null("Cart") as Sprite2D
	var wobble := bakery.get_node_or_null("Wobble")
	_check(cart != null and cart.z_index == -1, "cart draws behind the player")
	_check(wobble != null and wobble.z_index == 1, "Wobble draws above the cart")
	_check(wobble != null and wobble.data != null and wobble.data.id == &"wobble",
		"Wobble encounter is wired to its data")
	if wobble != null:
		_check(not wobble.visible and not wobble._active,
			"Wobble waits out of sight before the quest starts")

	var choice := hub.get_node_or_null("Npc/DialogInteraction/DialogChoice")
	var bakery_branch: DialogBranch = null
	if choice != null:
		bakery_branch = choice.get_node_or_null("DialogBranch5") as DialogBranch
	_check(bakery_branch != null, "Kunal keeps his progress hint")
	if bakery_branch != null:
		_check(not bakery_branch.is_available(),
			"Kunal's hint stays quiet before Priya's intro")

	if wobble == null:
		hub.queue_free()
		return

	# Walk to the cart before the quest and try to start the encounter.
	var player := hub.get_node_or_null("Player") as CharacterBody2D
	_check(player != null, "player is in the hub")
	if player != null:
		player.global_position = wobble.global_position + Vector2(0, -45)
		await get_tree().physics_frame
		await get_tree().physics_frame
		Input.action_press("down")
		for i in 45:
			await get_tree().physics_frame
			if wobble.player_near:
				break
		Input.action_release("down")
		_check(wobble.player_near, "the player can stand at the bakery cart")
		_check(not wobble.get_node("Prompt").visible,
			"Wobble shows no prompt before the quest")
		wobble._start_encounter()
		await get_tree().process_frame
		_check(not DialogSystem.is_active, "no equipment dialog starts before the quest")

	# Priya hands over the notebook. The hub wakes up and Kunal has advice.
	GameState.set_flag("got_notebook", true)
	await get_tree().process_frame
	await get_tree().process_frame
	_check(wobble.visible and wobble._active, "Wobble appears once the notebook is in hand")
	_check(wobble.get_node("Prompt").visible, "Wobble prompts after the quest starts")
	if bakery_branch != null:
		_check(bakery_branch.is_available() and bakery_branch.text == "Any clinic tips?",
			"Kunal points at the clinic first")
		_check(_choice_labels(choice).has("Any clinic tips?"),
			"Kunal's menu shows the clinic option")

	GameState.recover_item(&"mirror_set")
	GameState.set_flag("villain_blorb_cleared", true)
	GameState.set_quest_stage("restore_clinic", 3)
	if bakery_branch != null:
		_check(bakery_branch.is_available() and bakery_branch.text == "Any bakery tips?",
			"Kunal points at the bakery once Blorb is gone")
		_check(_choice_labels(choice).has("Any bakery tips?"),
			"Kunal's menu shows the bakery option")

	# Play the Wobble encounter through to the chair.
	wobble._start_encounter()
	await get_tree().create_timer(0.2).timeout
	_check(DialogSystem.is_active, "Wobble intro dialog is active")
	if DialogSystem.is_active:
		DialogSystem.hide_dialog()
	await get_tree().process_frame
	await get_tree().process_frame

	var challenge: Node = hub.get_node_or_null("ChairBalance")
	_check(challenge != null, "chair challenge opened")
	if challenge != null:
		_check(challenge.duration == 12.0, "chair challenge asks for twelve seconds")
		var play_area := challenge.get_node_or_null("Frame/Margin/VBox/PlayArea")
		_check(play_area != null and play_area.get_child_count() >= 3,
			"chair challenge builds its play area")
		challenge.time_left = 0.0
		challenge._on_tick(0.0)
		await get_tree().process_frame
		_check(not challenge.running, "surviving the timer completes the challenge")
		_check(challenge.continue_button.visible, "success shows the continue button")
		challenge._on_continue_pressed()
		await get_tree().create_timer(0.2).timeout

	_check(GameState.has_item(&"chair"), "dental chair recovered")
	_check(GameState.has_flag("villain_wobble_cleared"), "Wobble cleared flag set")
	_check(GameState.get_quest_stage("restore_clinic") == 3,
		"quest stays at stage 3 until all equipment is back")
	if DialogSystem.is_active:
		DialogSystem.hide_dialog()
	await get_tree().process_frame
	await get_tree().process_frame
	_check(wobble == null or not is_instance_valid(wobble), "Wobble leaves after victory")
	if bakery_branch != null:
		_check(bakery_branch.is_available(),
			"Kunal's hint survives finishing the bakery")
		_check(bakery_branch.text == "Any light tips?",
			"Kunal's hint moves on to the curing light")
		_check(_choice_labels(choice).has("Any light tips?"),
			"Kunal's menu still has a progress option after the bakery")

	hub.queue_free()
	await get_tree().process_frame


func _check_priya_grants_notebook() -> void:
	# Pressing E on Priya works just as well as waiting for the auto-greet.
	GameState.new_game()
	SceneRouter.next_spawn = &"clinic_door"
	var clinic: Node = load(CLINIC_PATH).instantiate()
	get_tree().root.add_child(clinic)
	get_tree().current_scene = clinic
	await get_tree().process_frame
	await get_tree().process_frame

	var priya := clinic.get_node_or_null("Priya")
	var blorb := clinic.get_node_or_null("Blorb")
	_check(priya != null, "Priya loads for the intro")
	_check(not GameState.quest_started(), "the quest starts closed")
	if blorb != null:
		_check(not blorb.visible and not blorb._active,
			"Blorb waits until the quest starts")
	if priya == null:
		clinic.queue_free()
		return

	var interaction := priya.get_node_or_null("DialogInteraction") as DialogInteraction
	_check(interaction != null, "Priya has an interaction")
	if interaction != null:
		interaction.player_interact()
		await get_tree().process_frame
		_check(DialogSystem.is_active, "Priya's intro opens on demand")
		DialogSystem.hide_dialog()
		await get_tree().process_frame
		await get_tree().process_frame
		_check(GameState.quest_started(), "finishing Priya's intro starts the quest")
		_check(GameState.has_flag("got_toothbrush"), "the toothbrush is handed over")
		_check(GameState.get_quest_stage("restore_clinic") == 2,
			"the intro advances the quest to stage 2")

	if blorb != null and is_instance_valid(blorb):
		_check(blorb.visible and blorb._active, "Blorb wakes up after the intro")

	clinic.queue_free()
	await get_tree().process_frame


func _check_challenge_retry_and_skip() -> void:
	# Keep this independent from the encounter so it also covers a stand-alone
	# challenge and the inherited retry/skip rules.
	var solo: ChairBalance = load(CHALLENGE_PATH).instantiate()
	add_child(solo)
	await get_tree().process_frame
	_check(get_tree().paused, "a challenge pauses the world")
	_check(solo.title_label.text == "Chair Balance", "chair challenge has its title")
	_check(solo.timer_bar.value > 95.0, "timer starts near full")

	Input.action_press("left")
	await get_tree().process_frame
	_check(solo._input_direction() < 0.0, "A steers the chair left")
	Input.action_release("left")

	solo.tilt = 1.2
	solo._on_tick(0.0)
	await get_tree().process_frame
	_check(not solo.running, "leaning too far fails the challenge")
	_check(solo.retry_button.visible, "failure offers a retry")
	solo._on_retry_pressed()
	solo.fail()
	solo._on_retry_pressed()
	solo.fail()
	await get_tree().process_frame
	_check(solo.skip_button.visible, "skip is offered after three failed attempts")
	solo._on_skip_pressed()
	await get_tree().process_frame
	_check(not is_instance_valid(solo), "skipping closes the challenge")
	_check(not get_tree().paused, "skipping unpauses the world")


func _check_repeat_dialog() -> void:
	var clinic: Node = load(CLINIC_PATH).instantiate()
	get_tree().root.add_child(clinic)
	get_tree().current_scene = clinic
	await get_tree().process_frame
	await get_tree().process_frame

	var priya := clinic.get_node_or_null("Priya")
	var mehta := clinic.get_node_or_null("Mehta")
	_check(priya != null and mehta != null, "clinic NPCs load for the repeat dialog")
	if priya != null:
		var priya_text := _dialog_text(priya._build_dialog())
		_check("2 down" in priya_text, "Priya counts both recovered items")
		_check("Wobble left a note" in priya_text, "Priya reacts to the chair recovery")
	if mehta != null:
		var mehta_text := _dialog_text(mehta._build_dialog())
		_check("blob by the door is gone" in mehta_text,
			"Mr. Mehta notices that Blorb is gone")

	clinic.queue_free()
	await get_tree().process_frame


func _choice_labels(choice: DialogChoice) -> Array[String]:
	var labels: Array[String] = []
	if choice == null:
		return labels
	for branch in choice.dialog_branches:
		if branch.is_available():
			labels.append(branch.text)
	return labels


func _dialog_text(lines: Array[DialogItem]) -> String:
	var text := ""
	for line in lines:
		if line is DialogText:
			text += line.text + "\n"
	return text


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
