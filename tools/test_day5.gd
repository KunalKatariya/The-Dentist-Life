extends Node
## Smoke test for the Day 5 slice: summoning Kunal for a hint, the two village
## villains who hold the last equipment, the reception-bell finale and the
## proximity fix that keeps E from opening a conversation with a distant NPC.
## Run with: godot --headless --path . res://tools/test_day5.tscn

const HUB_PATH := "res://playground.tscn"
const CLINIC_PATH := "res://Scenes/Clinic/Clinic.tscn"

var failures: int = 0
var _save_backup: String = ""
var _had_save: bool = false


func _ready() -> void:
	_backup_save()
	await get_tree().process_frame

	_check_input()
	await _check_hint_lines()
	await _check_kunal_proximity()
	await _check_summon()
	await _check_pickups_and_bell()

	if DialogSystem.is_active:
		DialogSystem.hide_dialog()
	get_tree().paused = false
	_restore_save()
	GameState.load_game()

	print("DAY5 SMOKE: %d failure(s)" % failures)
	get_tree().quit(1 if failures > 0 else 0)


func _check_input() -> void:
	_check(InputMap.has_action("call_hint"), "the call_hint action exists")
	var has_h := false
	for event in InputMap.action_get_events("call_hint"):
		if event is InputEventKey and event.physical_keycode == KEY_H:
			has_h = true
	_check(has_h, "H is bound to calling Kunal")


func _check_hint_lines() -> void:
	var hint := load("res://Scenes/NPC/KunalHint.gd").new() as KunalHint
	GameState.new_game()
	GameState.set_flag("got_notebook", true)
	_check(hint.hint_lines()[0] == "Any clinic tips?", "hints start at the clinic")
	GameState.recover_item(&"mirror_set")
	_check(hint.hint_lines()[0] == "Any bakery tips?", "hints move to the bakery")
	GameState.recover_item(&"chair")
	_check(hint.hint_lines()[0] == "Any light tips?", "hints move to the tea lamp")
	GameState.recover_item(&"curing_light")
	_check(hint.hint_lines()[0] == "Any X-ray tips?", "hints move to the court")
	GameState.recover_item(&"xray")
	_check(hint.hint_lines()[0] == "Any cleaning tips?", "hints send the player to the old farm")
	GameState.recover_item(&"sterilizer")
	_check(hint.hint_lines()[0] == "Any paperwork tips?", "hints point at the flower shop")
	GameState.recover_item(&"records")
	_check(hint.hint_lines()[0] == "What's next?", "hints finish with the reception bell")
	GameState.set_flag("clinic_restored", true)
	_check(not hint.is_available(), "hints retire after the clinic reopens")
	_check(hint.hint_lines()[0] == "How is the clinic?",
		"Kunal still has a closing line after the reopening")
	hint.free()
	await get_tree().process_frame


func _check_kunal_proximity() -> void:
	var hub := await _fresh_hub()
	var npc := hub.get_node_or_null("Npc")
	var interaction := npc.get_node_or_null("DialogInteraction") as DialogInteraction
	_check(interaction != null, "Kunal has a dialog interaction")
	if interaction == null:
		await _free_scene(hub)
		return

	_check(not interaction.player_in_area,
		"Kunal's conversation is not armed when the player is far away")
	var event := InputEventAction.new()
	event.action = "interact"
	event.pressed = true
	interaction._unhandled_input(event)
	await get_tree().process_frame
	_check(not DialogSystem.is_active, "E away from Kunal does not start his dialog")
	await _free_scene(hub)


func _check_summon() -> void:
	var hub := await _fresh_hub()
	GameState.set_flag("got_notebook", true)
	GameState.set_quest_stage("restore_clinic", 3)
	GameState.recover_item(&"mirror_set")
	GameState.recover_item(&"chair")
	GameState.recover_item(&"curing_light")
	GameState.recover_item(&"xray")
	await get_tree().process_frame

	var npc := hub.get_node_or_null("Npc") as Node2D
	var player := hub.get_node_or_null("Player") as Node2D
	_check(npc != null and player != null, "the hub has Kunal and the player")
	if npc == null or player == null:
		await _free_scene(hub)
		return

	player.global_position = npc.global_position + Vector2(200, 0)
	hub._summon_kunal()
	await get_tree().create_timer(0.15).timeout
	_check(hub._kunal_busy, "summoning Kunal takes control for a moment")
	for i in 120:
		await get_tree().process_frame
		if DialogSystem.is_active:
			break
	_check(DialogSystem.is_active, "Kunal walks over and starts the hint")
	_check(npc.global_position.distance_to(player.global_position) < 48.0,
		"Kunal stands beside the player")
	_check(DialogSystem.dialog_items.size() >= 3, "the summoned hint has a short conversation")

	if DialogSystem.is_active:
		DialogSystem.hide_dialog()
	await get_tree().process_frame
	await get_tree().process_frame
	_check(not hub._kunal_busy, "the player gets control back after the hint")
	_check(player.input_enabled, "the player can move again after the hint")
	await _free_scene(hub)


func _check_pickups_and_bell() -> void:
	# The last two pieces live in the village now, guarded by Mildew and Redtape.
	var hub := await _fresh_hub()
	GameState.set_flag("got_notebook", true)
	GameState.set_quest_stage("restore_clinic", 3)
	for item in [&"mirror_set", &"chair", &"curing_light", &"xray"]:
		GameState.recover_item(item)
	await get_tree().process_frame

	var nook := hub.get_node_or_null("MildewNook") as Node2D
	var cart := hub.get_node_or_null("RecordsCart") as Node2D
	_check(nook != null, "Mildew waits in the village")
	_check(cart != null, "Redtape waits in the village")
	if nook != null:
		var mildew := nook.get_node_or_null("Mildew")
		_check(mildew != null and mildew.visible and mildew._active,
			"Mildew is visible beside the old well")
		_check(nook.position.distance_to(Vector2(0, 75)) < 90.0,
			"Mildew stands by the well")
	if cart != null:
		var redtape := cart.get_node_or_null("Redtape")
		_check(redtape != null and redtape.visible and redtape._active,
			"Redtape is visible at the flower shop")
	await _free_scene(hub)

	var clinic := await _fresh_clinic_with_four_items()
	var bell := clinic.get_node_or_null("ReceptionBell") as ReceptionBell
	var player := clinic.get_node_or_null("Player") as Node2D
	_check(clinic.get_node_or_null("SterilizerPickup") == null,
		"the sterilizer is no longer inside the clinic")
	_check(clinic.get_node_or_null("RecordsPickup") == null,
		"the records are no longer inside the clinic")
	_check(bell != null and not bell.visible, "the reception bell waits for all six pieces")

	if bell == null or player == null:
		await _free_scene(clinic)
		return

	GameState.recover_item(&"sterilizer")
	await get_tree().process_frame
	_check(GameState.has_item(&"sterilizer"), "the sterilizer goes into the notebook")
	_check(GameState.get_quest_stage("restore_clinic") == 3,
		"five of six keeps the hunt going")
	_check(not bell.visible, "the bell stays hidden at five pieces")

	GameState.recover_item(&"records")
	await get_tree().process_frame
	_check(GameState.has_item(&"records"), "the records go into the notebook")
	_check(bell.visible, "the reception bell appears once all six are home")
	var bell_sprite := bell.get_node_or_null("Sprite2D") as Sprite2D
	_check(ItemCatalog.get_item(ItemCatalog.BELL_ID) != null,
		"the reception bell has an item entry")
	_check(bell_sprite != null and bell_sprite.texture != null,
		"the reception bell shows its icon on the counter")

	player.global_position = bell.global_position + Vector2(-15, 13)
	await _wait_physics(4)
	_check(bell.player_near, "the player can reach the reception bell")
	_check(bell.prompt.visible, "the reception bell shows its E prompt")
	bell._ring()
	await get_tree().process_frame
	await get_tree().process_frame
	_check(DialogSystem.is_active, "ringing the bell starts the finale")
	if DialogSystem.is_active:
		DialogSystem.hide_dialog()
	await get_tree().process_frame
	await get_tree().process_frame
	_check(GameState.has_flag("clinic_restored"), "the clinic is marked open")
	_check(GameState.get_quest_stage("restore_clinic") == 5, "the quest reaches its final stage")
	_check(GameState.has_sticker("clinic_restored"), "the reopening earns a sticker")
	_check(not is_instance_valid(bell), "the bell leaves after the reopening")
	await _free_scene(clinic)


func _fresh_hub() -> Node:
	GameState.new_game()
	GameState.set_flag("met_clerk", true)
	var hub: Node = load(HUB_PATH).instantiate()
	get_tree().root.add_child(hub)
	get_tree().current_scene = hub
	await get_tree().process_frame
	await get_tree().process_frame
	return hub


func _fresh_clinic_with_four_items() -> Node:
	GameState.new_game()
	GameState.set_flag("got_notebook", true)
	GameState.set_flag("villain_rattle_cleared", true)
	GameState.set_quest_stage("restore_clinic", 3)
	for item in [&"mirror_set", &"chair", &"curing_light", &"xray"]:
		GameState.recover_item(item)
	var clinic: Node = load(CLINIC_PATH).instantiate()
	get_tree().root.add_child(clinic)
	get_tree().current_scene = clinic
	await get_tree().process_frame
	await get_tree().process_frame
	return clinic


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
