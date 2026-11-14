class_name ReceptionBell extends Area2D
## The finale. Once all six pieces of equipment are home, the reception bell
## starts glowing on the clinic counter. Ringing it reopens the clinic.

const PLAYER_INFO := preload("res://Scenes/NPC/npc_player.tres")
const PRIYA_INFO := preload("res://Scenes/NPC/priya.tres")

var player_near: bool = false
var _time: float = 0.0
var _ringing: bool = false
var _sprite_base_y: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var prompt: Label = $Prompt


func _ready() -> void:
	if GameState.has_flag("clinic_restored") or GameState.get_quest_stage("restore_clinic") >= 5:
		queue_free()
		return

	var item := ItemCatalog.get_item(ItemCatalog.BELL_ID)
	if item != null and item.icon != null:
		sprite.texture = item.icon
	_sprite_base_y = sprite.position.y
	prompt.hide()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	GameState.item_recovered.connect(_on_item_recovered)
	_refresh_lock()


func _process(delta: float) -> void:
	if not visible:
		return
	_time += delta
	sprite.position.y = _sprite_base_y + sin(_time * 2.2) * 1.0


func _refresh_lock() -> void:
	var unlocked := GameState.recovered_count() >= ItemCatalog.TOTAL
	visible = unlocked
	set_deferred("monitoring", unlocked)
	if not unlocked:
		player_near = false
		prompt.hide()


func _on_item_recovered(_item_id: StringName) -> void:
	_refresh_lock()


func _on_body_entered(body: Node2D) -> void:
	if not visible or _ringing or not body is Player:
		return
	player_near = true
	prompt.show()


func _on_body_exited(body: Node2D) -> void:
	if not body is Player:
		return
	player_near = false
	prompt.hide()


func _unhandled_input(event: InputEvent) -> void:
	if not player_near or not visible or _ringing:
		return
	if not event.is_action_pressed("interact") or event.is_echo():
		return
	if get_tree().paused or DialogSystem.is_active:
		return
	get_viewport().set_input_as_handled()
	_ring()


func _ring() -> void:
	_ringing = true
	player_near = false
	prompt.hide()

	var lines := [
		[PRIYA_INFO, "All six. Even the little bell. I do not know whether to laugh or cry."],
		[PLAYER_INFO, "Then let us open the clinic."],
		[PRIYA_INFO, "Ring it, Doctor."],
	]
	var items: Array[DialogItem] = []
	for entry in lines:
		var line := DialogText.new()
		line.npc_info = entry[0]
		line.text = entry[1]
		items.append(line)
	DialogSystem.show_dialog(items)
	await DialogSystem.finished
	for line in items:
		if is_instance_valid(line):
			line.queue_free()

	GameState.set_flag("equipment_complete", true)
	GameState.set_flag("clinic_restored", true)
	GameState.set_quest_stage("restore_clinic", 5)
	GameState.add_sticker("clinic_restored")
	GameHUD.toast("The clinic is open again!")
	queue_free()
