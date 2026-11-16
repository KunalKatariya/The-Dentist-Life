extends Node
## Smoke test for the ending slice: the reopening card, its fallback on a save
## that already finished the quest, the expanded bell finale, the post-finale
## clinic dialog and the spacing between the three hub villains.
## Run with: godot --headless --path . res://tools/test_day6.tscn

const HUB_PATH := "res://playground.tscn"
const CLINIC_PATH := "res://Scenes/Clinic/Clinic.tscn"
const CARD_PATH := "res://GUI/ending_card.tscn"
const VILLAIN_IDS := ["blorb", "wobble", "gloam", "rattle", "mildew", "redtape"]
const ALL_ITEMS := [&"mirror_set", &"chair", &"curing_light", &"xray", &"sterilizer", &"records"]

var failures: int = 0
var _save_backup: String = ""
var _had_save: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_backup_save()
	await get_tree().process_frame

	await _check_ending_card()
	await _check_fallback()
	await _check_bell_finale()
	await _check_post_finale_dialog()
	await _check_villain_spacing()

	if DialogSystem.is_active:
		DialogSystem.hide_dialog()
	get_tree().paused = false
	_restore_save()
	GameState.load_game()

	print("DAY6 SMOKE: %d failure(s)" % failures)
	get_tree().quit(1 if failures > 0 else 0)


func _check_ending_card() -> void:
	_reach_ending()
	var card = load(CARD_PATH).instantiate()
	get_tree().root.add_child(card)
	await get_tree().process_frame
	_check(not card.visible, "the ending card starts hidden")
	_check(not card.is_open(), "the ending card starts closed")

	card.open()
	await get_tree().process_frame
	_check(card.visible and card.is_open(), "opening the card shows it")
	_check(GameState.has_flag("ending_seen"), "opening the card records the ending")
	_check(get_tree().paused, "the ending card pauses the world")

	var stats: String = card.stats_label.text
	_check("6 / 6" in stats, "the card reports all six pieces of equipment")
	_check("Villains befriended    6 / 6" in stats,
		"the card reports all six villains befriended")
	_check("Stickers collected" in stats, "the card shows the sticker count")
	_check("Steve" in card.flavor_label.text, "the card closes on the waiting-room joke")
	_check(card.stay_button.text == "Stay in the clinic", "the card offers staying in the clinic")
	_check(card.menu_button.text == "Main menu", "the card offers the main menu")

	card.close()
	await get_tree().process_frame
	_check(not card.visible and not card.is_open(), "staying closes the card")
	_check(not get_tree().paused, "staying unpauses the world")

	card.queue_free()
	await get_tree().process_frame


func _check_fallback() -> void:
	_reach_ending()
	GameState.clear_flag("ending_seen")
	var clinic := await _fresh_clinic()
	await _wait_frames(5)
	var card = clinic.get_node_or_null("EndingCard")
	_check(card != null, "a finished save shows the ending card on arrival")
	if card == null:
		await _free_scene(clinic)
		return
	_check(card.visible and card.is_open(), "the fallback card is on screen")
	_check(GameState.has_flag("ending_seen"), "the fallback card records the ending once")
	_check(get_tree().paused, "the fallback card takes control of the game")

	var player := clinic.get_node_or_null("Player") as Player
	_check(player != null and not player.input_enabled,
		"the player cannot walk around behind the fallback card")

	card.close()
	await get_tree().process_frame
	_check(player != null and player.input_enabled,
		"staying in the clinic gives the player control back")
	_check(not get_tree().paused, "the fallback card unpauses when dismissed")

	# A second visit must not show the card again.
	await _free_scene(clinic)
	var revisit := await _fresh_clinic()
	await _wait_frames(4)
	_check(revisit.get_node_or_null("EndingCard") == null,
		"the ending card does not return on later clinic visits")
	await _free_scene(revisit)


func _check_bell_finale() -> void:
	_start_clinic_save()
	GameState.set_quest_stage("restore_clinic", 4)
	for item in ALL_ITEMS:
		GameState.recover_item(item)

	var clinic := await _fresh_clinic()
	var bell := clinic.get_node_or_null("ReceptionBell") as ReceptionBell
	var player := clinic.get_node_or_null("Player") as Node2D
	_check(bell != null and bell.visible, "the reception bell is ready once all six are home")
	_check(clinic.get_node_or_null("EndingCard") == null,
		"the ending card waits for the bell")
	if bell == null:
		await _free_scene(clinic)
		return

	player.global_position = bell.global_position + Vector2(-15, 13)
	await _wait_physics(4)
	_check(bell.player_near, "the player can still reach the reception bell")
	bell._ring()
	await _wait_frames(2)

	_check(DialogSystem.is_active, "ringing the bell opens the finale conversation")
	var names: Array[String] = []
	if DialogSystem.is_active:
		for item in DialogSystem.dialog_items:
			if item is DialogText and item.npc_info != null:
				names.append(item.npc_info.npc_name)
	_check(DialogSystem.dialog_items.size() >= 8, "the finale is a full scene, not a single line")
	_check("Priya" in names, "Priya leads the reopening")
	_check("Mr. Mehta" in names, "Mr. Mehta and Steve join the reopening")
	_check("Kunal" in names, "Kunal brings his banner to the reopening")

	if DialogSystem.is_active:
		DialogSystem.hide_dialog()
	await _wait_frames(3)
	_check(GameState.get_quest_stage("restore_clinic") == 5, "the finale reaches the last quest stage")
	_check(GameState.has_flag("clinic_restored"), "the finale marks the clinic open")
	_check(GameState.has_flag("ending_seen"), "the finale shows and records the ending card")

	var card = clinic.get_node_or_null("EndingCard")
	_check(card != null and card.visible, "the finale opens the ending card")
	_check(not is_instance_valid(bell), "the bell leaves after the reopening")
	if card != null:
		card.close()
		await get_tree().process_frame
	await _free_scene(clinic)


func _check_post_finale_dialog() -> void:
	_reach_ending()
	GameState.set_flag("ending_seen", true)
	var clinic := await _fresh_clinic()
	var priya := clinic.get_node_or_null("Priya") as ClinicNpc
	var mehta := clinic.get_node_or_null("Mehta") as ClinicNpc
	_check(priya != null and mehta != null, "the clinic NPCs load after the reopening")
	if priya != null:
		var text := _dialog_text(priya._build_dialog())
		_check("kettle is on" in text, "Priya has a post-reopening conversation")
		_check("waiting room" in text, "Priya talks about the full waiting room")
	if mehta != null:
		var text := _dialog_text(mehta._build_dialog())
		_check("appointment" in text, "Mr. Mehta books Steve in after the reopening")
	await _free_scene(clinic)

	# The last two pieces are in the village, so Priya should point at Mildew
	# and Redtape instead of the clinic.
	GameState.new_game()
	GameState.set_flag("got_notebook", true)
	GameState.set_quest_stage("restore_clinic", 3)
	for item in [&"mirror_set", &"chair", &"curing_light", &"xray"]:
		GameState.recover_item(item)
	var hunt := await _fresh_clinic()
	var hunting_priya := hunt.get_node_or_null("Priya") as ClinicNpc
	var hunt_text := _dialog_text(hunting_priya._build_dialog())
	_check("old farm well" in hunt_text,
		"Priya points at Mildew by the old well")
	_check("flower shop" in hunt_text,
		"Priya points at Redtape at the flower shop")
	_check(not "never left the building" in hunt_text,
		"Priya no longer hides the last two inside the clinic")
	GameState.recover_item(&"sterilizer")
	hunt_text = _dialog_text(hunting_priya._build_dialog())
	_check("records folder" in hunt_text, "Priya points at the last records folder")
	GameState.recover_item(&"records")
	hunt_text = _dialog_text(hunting_priya._build_dialog())
	_check("All six" in hunt_text,
		"Priya wraps up once the last piece is home")
	await _free_scene(hunt)


func _check_villain_spacing() -> void:
	GameState.new_game()
	GameState.set_flag("got_notebook", true)
	var hub: Node = load(HUB_PATH).instantiate()
	get_tree().root.add_child(hub)
	get_tree().current_scene = hub
	await _wait_frames(2)

	var bakery := hub.get_node_or_null("BakeryCart") as Node2D
	var lamp := hub.get_node_or_null("TeaLamp") as Node2D
	var xray := hub.get_node_or_null("XrayBoard") as Node2D
	var nook := hub.get_node_or_null("MildewNook") as Node2D
	var cart := hub.get_node_or_null("RecordsCart") as Node2D
	_check(
		bakery != null and lamp != null and xray != null and nook != null and cart != null,
		"all five hub villains load",
	)
	if bakery == null or lamp == null or xray == null or nook == null or cart == null:
		await _free_scene(hub)
		return

	_check(bakery.position == Vector2(1540, 130), "Wobble stays at the bakery cart")
	_check(lamp.position == Vector2(1160, 620), "Gloam moves down beside the dance academy")
	_check(xray.position == Vector2(505, 650), "Rattle stays at the X-ray board")
	_check(nook.position == Vector2(48, 62), "Mildew stands right beside the old well")
	_check(cart.position == Vector2(860, -150), "Redtape stays at the flower shop")

	var spots: Array[Vector2] = [
		bakery.position,
		lamp.position,
		xray.position,
		nook.position,
		cart.position,
	]
	var closest := 1e20
	for i in spots.size():
		for j in range(i + 1, spots.size()):
			closest = minf(closest, spots[i].distance_to(spots[j]))
	_check(closest >= 500.0,
		"the five villains are at least 500 pixels apart (closest %.0f)" % closest)
	_check(nook.position.distance_to(Vector2(0, 75)) < 90.0,
		"Mildew is genuinely beside the well")
	await _free_scene(hub)


func _reach_ending() -> void:
	GameState.new_game()
	GameState.set_flag("got_notebook", true)
	for item in ALL_ITEMS:
		GameState.recover_item(item)
	for id in VILLAIN_IDS:
		GameState.set_flag("villain_%s_cleared" % id, true)
		GameState.add_sticker(id)
	GameState.set_flag("clinic_restored", true)
	GameState.add_sticker("clinic_restored")
	GameState.set_quest_stage("restore_clinic", 5)


func _start_clinic_save() -> void:
	GameState.new_game()
	GameState.set_flag("got_notebook", true)
	for id in VILLAIN_IDS:
		GameState.set_flag("villain_%s_cleared" % id, true)


func _fresh_clinic() -> Node:
	var clinic: Node = load(CLINIC_PATH).instantiate()
	get_tree().root.add_child(clinic)
	get_tree().current_scene = clinic
	await _wait_frames(2)
	return clinic


func _dialog_text(lines: Array[DialogItem]) -> String:
	var text := ""
	for line in lines:
		if line is DialogText:
			text += line.text + "\n"
		line.free()
	return text


func _wait_frames(frames: int) -> void:
	for i in frames:
		await get_tree().process_frame


func _wait_physics(frames: int) -> void:
	for i in frames:
		await get_tree().physics_frame


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
