extends Node
## Smoke test for the Day 4 slice: Gloam at the tea lamp, Rattle at the X-ray
## board, the curing-beam and bone-flash challenges, and Kunal's next hints.
## Run with: godot --headless --path . res://tools/test_day4.tscn

const HUB_PATH := "res://playground.tscn"
const BEAM_PATH := "res://Challenges/curing_beam.tscn"
const MEMORY_PATH := "res://Challenges/xray_memory.tscn"

var failures: int = 0
var _save_backup: String = ""
var _had_save: bool = false


func _ready() -> void:
	_backup_save()
	await get_tree().process_frame

	_check_art()
	_check_resources()
	await _check_hub_before_and_after_quest()
	await _check_curing_beam_mechanics()
	await _check_xray_mechanics()
	await _check_gloam_encounter()
	await _check_rattle_encounter()

	_restore_save()
	GameState.load_game()

	print("DAY4 SMOKE: %d failure(s)" % failures)
	get_tree().quit(1 if failures > 0 else 0)


func _check_art() -> void:
	var gloam: Texture2D = load("res://Assets_Imported/villains/gloam.png")
	var gloam_portrait: Texture2D = load("res://Assets_Imported/villains/gloam_portrait.png")
	var rattle: Texture2D = load("res://Assets_Imported/villains/rattle.png")
	var rattle_portrait: Texture2D = load("res://Assets_Imported/villains/rattle_portrait.png")
	var lamp: Texture2D = load("res://Assets_Imported/town/tea_lamp.png")
	var board: Texture2D = load("res://Assets_Imported/town/xray_board.png")
	_check(gloam != null and gloam.get_width() == 64 and gloam.get_height() == 64,
		"Gloam world sprite is 64x64")
	_check(rattle != null and rattle.get_width() == 64 and rattle.get_height() == 64,
		"Rattle world sprite is 64x64")
	_check(gloam_portrait != null and gloam_portrait.get_width() == 400
		and gloam_portrait.get_height() == 148, "Gloam portrait is four 100x148 frames")
	_check(rattle_portrait != null and rattle_portrait.get_width() == 400
		and rattle_portrait.get_height() == 148, "Rattle portrait is four 100x148 frames")
	_check(lamp != null and lamp.get_width() == 32 and lamp.get_height() == 64,
		"tea lamp sprite is 32x64")
	_check(board != null and board.get_width() == 48 and board.get_height() == 56,
		"X-ray board sprite is 48x56")


func _check_resources() -> void:
	var gloam: VillainResource = load("res://Data/villains/gloam.tres")
	var rattle: VillainResource = load("res://Data/villains/rattle.tres")
	_check(gloam != null, "Gloam villain resource loads")
	if gloam != null:
		_check(gloam.id == &"gloam", "Gloam keeps its id")
		_check(gloam.guarded_item_id == &"curing_light", "Gloam guards the curing light")
		_check(gloam.challenge_scene != null, "Gloam has a challenge scene")
		_check(gloam.npc_info != null and gloam.npc_info.portrait != null,
			"Gloam has a portrait for dialog")
		_check(gloam.intro_lines.size() >= 4 and gloam.victory_lines.size() >= 3,
			"Gloam has intro and victory dialog")
	_check(rattle != null, "Rattle villain resource loads")
	if rattle != null:
		_check(rattle.id == &"rattle", "Rattle keeps its id")
		_check(rattle.guarded_item_id == &"xray", "Rattle guards the X-ray machine")
		_check(rattle.challenge_scene != null, "Rattle has a challenge scene")
		_check(rattle.npc_info != null and rattle.npc_info.portrait != null,
			"Rattle has a portrait for dialog")
		_check(rattle.intro_lines.size() >= 4 and rattle.victory_lines.size() >= 3,
			"Rattle has intro and victory dialog")


func _check_hub_before_and_after_quest() -> void:
	GameState.new_game()
	GameState.set_flag("met_clerk", true)

	var hub: Node = load(HUB_PATH).instantiate()
	get_tree().root.add_child(hub)
	get_tree().current_scene = hub
	await get_tree().process_frame
	await get_tree().process_frame

	var lamp: Node = hub.get_node_or_null("TeaLamp")
	var board: Node = hub.get_node_or_null("XrayBoard")
	_check(lamp != null, "tea lamp is in the hub")
	_check(board != null, "X-ray board is in the hub")
	if lamp == null or board == null:
		hub.queue_free()
		return

	_check(lamp.position == Vector2(1160, 620), "tea lamp sits down by the dance academy")
	_check(board.position == Vector2(505, 650), "X-ray board sits by the court path")

	var gloam := lamp.get_node_or_null("Gloam")
	var rattle := board.get_node_or_null("Rattle")
	var lamp_sprite := lamp.get_node_or_null("Lamp") as Sprite2D
	var board_sprite := board.get_node_or_null("Board") as Sprite2D
	_check(lamp_sprite != null and lamp_sprite.z_index == -1, "tea lamp draws behind Gloam")
	_check(board_sprite != null and board_sprite.z_index == -1, "board draws behind Rattle")
	_check(gloam != null and gloam.z_index == 1, "Gloam draws above the lamp")
	_check(rattle != null and rattle.z_index == 1, "Rattle draws above the board")
	_check(gloam != null and gloam.data != null and gloam.data.id == &"gloam",
		"Gloam encounter is wired to its data")
	_check(rattle != null and rattle.data != null and rattle.data.id == &"rattle",
		"Rattle encounter is wired to its data")
	if gloam == null or rattle == null:
		hub.queue_free()
		return
	_check(not gloam.visible and not gloam._active,
		"Gloam waits out of sight before the quest starts")
	_check(not rattle.visible and not rattle._active,
		"Rattle waits out of sight before the quest starts")

	var choice := hub.get_node_or_null("Npc/DialogInteraction/DialogChoice")
	var hint: DialogBranch = null
	if choice != null:
		hint = choice.get_node_or_null("DialogBranch5") as DialogBranch
	_check(hint != null, "Kunal keeps his progress hint")
	if hint != null:
		_check(not hint.is_available(), "Kunal's hint stays quiet before Priya's intro")
	_check(InputMap.has_action("call_hint"), "the hub can summon Kunal with H")

	GameState.set_flag("got_notebook", true)
	await get_tree().process_frame
	await get_tree().process_frame
	_check(gloam.visible and gloam._active, "Gloam appears once the notebook is in hand")
	_check(rattle.visible and rattle._active, "Rattle appears once the notebook is in hand")
	if hint != null:
		_check(hint.is_available() and hint.text == "Any clinic tips?",
			"Kunal still points at the clinic first")

	GameState.recover_item(&"mirror_set")
	GameState.set_flag("villain_blorb_cleared", true)
	GameState.set_quest_stage("restore_clinic", 3)
	if hint != null:
		_check(hint.is_available() and hint.text == "Any bakery tips?",
			"Kunal points at the bakery once Blorb is gone")

	GameState.recover_item(&"chair")
	GameState.set_flag("villain_wobble_cleared", true)
	if hint != null:
		_check(hint.is_available() and hint.text == "Any light tips?",
			"Kunal points at the tea cart once the chair is home")
		_check(_choice_labels(choice).has("Any light tips?"),
			"Kunal's menu shows the light option")

	GameState.recover_item(&"curing_light")
	GameState.set_flag("villain_gloam_cleared", true)
	if hint != null:
		_check(hint.is_available() and hint.text == "Any X-ray tips?",
			"Kunal points at the court path once the light is home")
		_check(_choice_labels(choice).has("Any X-ray tips?"),
			"Kunal's menu shows the X-ray option")

	GameState.recover_item(&"xray")
	GameState.set_flag("villain_rattle_cleared", true)
	if hint != null:
		_check(hint.is_available() and hint.text == "Any cleaning tips?",
			"Kunal points back at the clinic once the X-ray is home")

	GameState.recover_item(&"sterilizer")
	if hint != null:
		_check(hint.is_available() and hint.text == "Any paperwork tips?",
			"Kunal points at the records folder after the sterilizer")

	GameState.recover_item(&"records")
	if hint != null:
		_check(hint.is_available() and hint.text == "What's next?",
			"Kunal points at the reception bell once all six are home")

	GameState.set_flag("clinic_restored", true)
	if hint != null:
		_check(not hint.is_available(), "Kunal's hint retires once the clinic reopens")

	hub.queue_free()
	await get_tree().process_frame


func _check_curing_beam_mechanics() -> void:
	var beam: CuringBeam = load(BEAM_PATH).instantiate()
	add_child(beam)
	await get_tree().process_frame
	_check(get_tree().paused, "the curing challenge pauses the world")
	_check(beam.title_label.text == "Catch the Light", "curing challenge has its title")
	_check(beam.duration == 20.0, "curing challenge gives twenty seconds")
	_check(beam.play_area.get_child_count() >= 4, "curing challenge builds track and target")
	_check(beam.beam_x < beam.target_x, "the beam starts outside the target band")

	for i in 3:
		beam.beam_x = beam.target_x
		beam._try_catch()
	await get_tree().process_frame
	_check(beam.catches == 3, "three catches fill the beam meter")
	_check(not beam.running, "three catches complete the challenge")
	_check(beam.continue_button.visible, "success shows the continue button")
	beam._on_continue_pressed()
	await get_tree().process_frame
	_check(not get_tree().paused, "finishing the curing challenge unpauses the world")

	var misses: CuringBeam = load(BEAM_PATH).instantiate()
	add_child(misses)
	await get_tree().process_frame
	for i in 3:
		misses.beam_x = misses.target_x + 100.0
		misses._try_catch()
	await get_tree().process_frame
	_check(misses.misses == 3, "three misses are counted")
	_check(not misses.running, "three misses end the attempt")
	_check(misses.retry_button.visible, "a failed attempt offers a retry")
	misses._on_skip_pressed()
	await get_tree().process_frame
	_check(not is_instance_valid(misses), "leaving the curing challenge closes it")
	_check(not get_tree().paused, "leaving the curing challenge unpauses the world")


func _check_xray_mechanics() -> void:
	var memory: XrayMemory = load(MEMORY_PATH).instantiate()
	add_child(memory)
	await get_tree().process_frame
	_check(get_tree().paused, "the bone-flash challenge pauses the world")
	_check(memory.title_label.text == "Bone Flashes", "bone-flash challenge has its title")
	_check(memory.duration == 25.0, "bone-flash challenge gives twenty-five seconds")
	_check(memory.showing, "the first sequence plays before input")
	_check(memory.sequence.size() == 3, "the first round is three flashes")

	memory.showing = false
	for direction in memory.sequence.duplicate():
		memory._handle_input(direction)
	_check(memory.round_index == 1, "repeating three flashes clears the first round")
	_check(memory.showing, "the second sequence plays automatically")
	_check(memory.sequence.size() == 4, "the second round is four flashes")

	memory.showing = false
	for direction in memory.sequence.duplicate():
		memory._handle_input(direction)
	await get_tree().process_frame
	_check(memory.round_index == 2, "repeating four flashes clears the second round")
	_check(not memory.running, "two clean rounds complete the challenge")
	_check(memory.continue_button.visible, "the X-ray challenge shows continue on success")
	memory._on_continue_pressed()
	await get_tree().process_frame
	_check(not get_tree().paused, "finishing the X-ray challenge unpauses the world")

	var mistaken: XrayMemory = load(MEMORY_PATH).instantiate()
	add_child(mistaken)
	await get_tree().process_frame
	mistaken.showing = false
	mistaken._handle_input(_wrong_direction(mistaken.sequence[0]))
	_check(mistaken.mistakes == 1, "a wrong flash is counted")
	_check(mistaken.showing, "a wrong flash replays the sequence")
	_check(mistaken.sequence.size() >= 3, "the replay keeps a full sequence")
	mistaken.showing = false
	mistaken._handle_input(_wrong_direction(mistaken.sequence[0]))
	await get_tree().process_frame
	_check(mistaken.mistakes == 2, "a second wrong flash is counted")
	_check(not mistaken.running, "two wrong flashes end the attempt")
	_check(mistaken.retry_button.visible, "the X-ray failure offers a retry")
	mistaken.queue_free()
	await get_tree().process_frame
	_check(not get_tree().paused, "freeing a failed X-ray challenge unpauses the world")


func _check_gloam_encounter() -> void:
	var hub := await _fresh_hub()
	if hub == null:
		return

	var lamp: Node = hub.get_node_or_null("TeaLamp")
	var gloam: Node = null
	if lamp != null:
		gloam = lamp.get_node_or_null("Gloam")
	_check(gloam != null, "Gloam is ready at the tea lamp")
	if gloam == null:
		hub.queue_free()
		return

	gloam._start_encounter()
	await get_tree().create_timer(0.2).timeout
	_check(DialogSystem.is_active, "Gloam's intro dialog is active")
	if DialogSystem.is_active:
		DialogSystem.hide_dialog()
	await get_tree().process_frame
	await get_tree().process_frame

	var challenge: Node = hub.get_node_or_null("CuringBeam")
	_check(challenge != null, "the curing challenge opens after Gloam's intro")
	if challenge != null:
		for i in 3:
			challenge.beam_x = challenge.target_x
			challenge._try_catch()
		await get_tree().process_frame
		_check(not challenge.running, "catching the beam beats Gloam")
		challenge._on_continue_pressed()
		await get_tree().create_timer(0.2).timeout

	_check(GameState.has_item(&"curing_light"), "the curing light is recovered")
	_check(GameState.has_flag("villain_gloam_cleared"), "Gloam's cleared flag is set")
	if DialogSystem.is_active:
		DialogSystem.hide_dialog()
	await get_tree().process_frame
	await get_tree().process_frame
	_check(gloam == null or not is_instance_valid(gloam), "Gloam leaves after victory")

	hub.queue_free()
	await get_tree().process_frame


func _check_rattle_encounter() -> void:
	var hub := await _fresh_hub()
	if hub == null:
		return

	var board: Node = hub.get_node_or_null("XrayBoard")
	var rattle: Node = null
	if board != null:
		rattle = board.get_node_or_null("Rattle")
	_check(rattle != null, "Rattle is ready at the X-ray board")
	if rattle == null:
		hub.queue_free()
		return

	rattle._start_encounter()
	await get_tree().create_timer(0.2).timeout
	_check(DialogSystem.is_active, "Rattle's intro dialog is active")
	if DialogSystem.is_active:
		DialogSystem.hide_dialog()
	await get_tree().process_frame
	await get_tree().process_frame

	var challenge: Node = hub.get_node_or_null("XrayMemory")
	_check(challenge != null, "the bone-flash challenge opens after Rattle's intro")
	if challenge != null:
		for round_index in 2:
			challenge.showing = false
			for direction in challenge.sequence.duplicate():
				challenge._handle_input(direction)
		await get_tree().process_frame
		_check(not challenge.running, "two clean rounds beat Rattle")
		challenge._on_continue_pressed()
		await get_tree().create_timer(0.2).timeout

	_check(GameState.has_item(&"xray"), "the X-ray machine is recovered")
	_check(GameState.has_flag("villain_rattle_cleared"), "Rattle's cleared flag is set")
	if DialogSystem.is_active:
		DialogSystem.hide_dialog()
	await get_tree().process_frame
	await get_tree().process_frame
	_check(rattle == null or not is_instance_valid(rattle), "Rattle leaves after victory")

	hub.queue_free()
	await get_tree().process_frame


func _fresh_hub() -> Node:
	GameState.new_game()
	GameState.set_flag("met_clerk", true)
	GameState.set_flag("got_notebook", true)
	GameState.set_flag("got_toothbrush", true)
	GameState.set_quest_stage("restore_clinic", 2)

	var hub: Node = load(HUB_PATH).instantiate()
	get_tree().root.add_child(hub)
	get_tree().current_scene = hub
	await get_tree().process_frame
	await get_tree().process_frame
	return hub


func _wrong_direction(correct: String) -> String:
	for direction in XrayMemory.DIRECTIONS:
		if direction != correct:
			return direction
	return "up"


func _choice_labels(choice: DialogChoice) -> Array[String]:
	var labels: Array[String] = []
	if choice == null:
		return labels
	for branch in choice.dialog_branches:
		if branch.is_available():
			labels.append(branch.text)
	return labels


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
