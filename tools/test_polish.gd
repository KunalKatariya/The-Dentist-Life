extends Node
## Regression checks for the dialogue portraits, NPC idle motion, player/NPC
## depth sorting and the wooden equipment HUD.
## Run with: godot --headless --path . res://tools/test_polish.tscn

const CLINIC_PATH := "res://Scenes/Clinic/Clinic.tscn"
const HUD_PATH := "res://GUI/game_hud.tscn"
const PORTRAITS := [
	"res://Scenes/NPC/Portraits/Priya_Dialogue.png",
	"res://Scenes/NPC/Portraits/Mehta_Dialogue.png",
	"res://Scenes/NPC/Portraits/npc_portrait_01.png",
]

var failures: int = 0
var _save_backup: String = ""
var _had_save: bool = false


func _ready() -> void:
	_backup_save()
	await get_tree().process_frame
	_check_portraits()
	await _check_hud_layout()
	await _check_npcs()
	print("POLISH SMOKE: %d failure(s)" % failures)
	get_tree().quit(1 if failures > 0 else 0)


func _check_portraits() -> void:
	for path in PORTRAITS:
		var texture: Texture2D = load(path)
		_check(texture != null, "%s loads" % path.get_file())
		if texture != null:
			_check(texture.get_width() == 400 and texture.get_height() == 148,
				"%s is four 100x148 frames" % path.get_file())
			var image := texture.get_image()
			_check(image != null and not image.is_empty(),
				"%s has readable art" % path.get_file())


func _check_hud_layout() -> void:
	var hud: Node = load(HUD_PATH).instantiate()
	add_child(hud)
	var panel := hud.get_node_or_null("Root/CounterPanel") as PanelContainer
	_check(panel != null, "HUD has an equipment panel")
	if panel != null:
		var style := panel.get_theme_stylebox("panel")
		_check(style is StyleBoxTexture, "equipment panel uses the wood sign art")
		_check(panel.offset_top >= 45.0,
			"equipment panel sits below the day/night clock")
	var counter := hud.get_node_or_null("Root/CounterPanel/Counter") as Label
	_check(counter != null, "HUD has an equipment label")
	if counter != null:
		var colour := counter.get_theme_color("font_color")
		_check(colour.get_luminance() < 0.3,
			"equipment label uses dark text for contrast")
	hud.queue_free()
	await get_tree().process_frame


func _check_npcs() -> void:
	var clinic: Node = load(CLINIC_PATH).instantiate()
	add_child(clinic)
	await get_tree().process_frame
	await get_tree().process_frame

	_check(clinic.y_sort_enabled, "clinic sorts characters by depth")

	var player := clinic.get_node_or_null("Player") as CharacterBody2D
	var priya := clinic.get_node_or_null("Priya") as CharacterBody2D
	var mehta := clinic.get_node_or_null("Mehta") as CharacterBody2D
	_check(player != null and priya != null and mehta != null,
		"clinic contains the player and both reception NPCs")
	if player == null or priya == null or mehta == null:
		clinic.queue_free()
		return

	_check(priya.collision_layer & 16 != 0, "Priya blocks the player")
	_check(mehta.collision_layer & 16 != 0, "Mr. Mehta blocks the player")
	_check(player.collision_mask & priya.collision_layer != 0,
		"player collision resolves against Priya")

	var anim := priya.get_node_or_null("AnimationPlayer") as AnimationPlayer
	var sprite := priya.get_node_or_null("Sprite2D") as Sprite2D
	_check(anim != null and anim.is_playing(), "Priya's idle animation is playing")
	if anim != null and sprite != null:
		var start_y := sprite.position.y
		var start_frame := sprite.frame
		await get_tree().create_timer(0.34).timeout
		var moved := absf(sprite.position.y - start_y) > 0.3
		var changed_frame := sprite.frame != start_frame
		_check(moved, "Priya's idle animation breathes")
		_check(changed_frame, "Priya's idle animation cycles frames")

	clinic.queue_free()
	await get_tree().process_frame


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
