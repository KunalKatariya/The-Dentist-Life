class_name Villain extends Area2D
## A world encounter that guards a stolen item. Talking to it starts a
## non-violent challenge. On success the item returns to the clinic.

const PLAYER_INFO := preload("res://Scenes/NPC/npc_player.tres")

@export var data: VillainResource

var player_near: bool = false
var _busy: bool = false
var _active: bool = false
var _sprite_base_y: float = 0.0
@onready var sprite: Sprite2D = $Sprite2D
@onready var prompt: Label = $Prompt
@onready var item_sprite: Sprite2D = $ItemSprite


func _ready() -> void:
	if data == null:
		push_warning("Villain has no VillainResource assigned")
		return

	if GameState.has_flag(data.cleared_flag()) or (data.guarded_item_id != &"" and GameState.has_item(data.guarded_item_id)):
		queue_free()
		return

	sprite.texture = data.sprite
	_sprite_base_y = sprite.position.y
	item_sprite.visible = false
	if data.guarded_item_id != &"":
		var item := ItemCatalog.get_item(data.guarded_item_id)
		if item != null and item.icon != null:
			item_sprite.texture = item.icon
			item_sprite.visible = true

	prompt.hide()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	# The robbery only begins after Priya hands over the notebook. Until then
	# the villain waits out of sight and cannot start a conversation.
	_active = GameState.quest_started()
	visible = _active
	if not _active:
		GameState.flag_changed.connect(_on_flag_changed)


func _process(_delta: float) -> void:
	if not _active or sprite == null:
		return
	sprite.position.y = _sprite_base_y + sin(Time.get_ticks_msec() / 380.0) * 2.0


func _on_flag_changed(flag: String, value: Variant) -> void:
	if flag == "got_notebook" and value == true:
		_activate()


func _activate() -> void:
	if _active:
		return
	_active = true
	visible = true
	if player_near and not _busy:
		prompt.show()


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		player_near = true
		if _active and not _busy:
			prompt.show()


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		player_near = false
		prompt.hide()


func _unhandled_input(event: InputEvent) -> void:
	if _active and player_near and not _busy and event.is_action_pressed("interact"):
		if get_tree().paused or DialogSystem.is_active:
			return
		get_viewport().set_input_as_handled()
		_start_encounter()


func _start_encounter() -> void:
	if not _active:
		return
	_busy = true
	prompt.hide()
	await _show_lines(data.intro_lines)
	await _run_challenge()


func _run_challenge() -> void:
	if data.challenge_scene == null:
		push_error("Villain '%s' has no challenge scene" % data.id)
		_busy = false
		return

	var challenge := data.challenge_scene.instantiate()
	get_tree().current_scene.add_child(challenge)
	var success: bool = await challenge.finished
	if success:
		await _win()
	else:
		await _show_lines(data.retreat_lines)
		_busy = false
		if player_near:
			prompt.show()


func _win() -> void:
	GameState.set_flag(data.cleared_flag(), true)
	if data.guarded_item_id != &"":
		GameState.recover_item(data.guarded_item_id)
	GameState.add_sticker(data.id)
	GameState.set_quest_stage("restore_clinic", 4 if GameState.recovered_count() >= ItemCatalog.TOTAL else 3)
	await _show_lines(data.victory_lines)
	if GameState.recovered_count() >= ItemCatalog.TOTAL:
		GameState.set_flag("equipment_complete", true)
		await _show_return_to_clinic()
	queue_free()


## The last recovery nudges the player back to Priya and the reception bell.
## The line is deliberately in the player's voice so it reads like a thought.
func _show_return_to_clinic() -> void:
	if GameState.has_flag("clinic_restored") or GameState.has_flag("clinic_return_prompted"):
		return
	GameState.set_flag("clinic_return_prompted", true)
	await _show_lines(PackedStringArray([
		"player:Hmm, I should head back to the clinic…",
		"player:That should be all six.",
		"player:Priya will want to hear it. I hope she has the kettle on.",
	]))


func _show_lines(lines: PackedStringArray) -> void:
	if lines.is_empty():
		return
	var items: Array[DialogItem] = []
	for text in lines:
		var line := DialogText.new()
		line.npc_info = PLAYER_INFO if text.begins_with("player:") else data.npc_info
		line.text = _strip_prefix(text)
		items.append(line)
	DialogSystem.show_dialog(items)
	await DialogSystem.finished
	for line in items:
		if is_instance_valid(line):
			line.queue_free()


func _strip_prefix(text: String) -> String:
	if text.begins_with("player:"):
		return text.substr(7)
	if text.begins_with("me:"):
		return text.substr(3)
	return text
