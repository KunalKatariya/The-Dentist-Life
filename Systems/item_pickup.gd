class_name ItemPickup extends Area2D
## A piece of clinic equipment lying somewhere in the world. Walk up and press
## E to add it to the notebook. Optionally stays invisible until a quest flag
## is set, so late-game pickups do not appear during the first hunt.

@export var item_id: StringName = &""
## Pickup only appears once this flag is set. Empty = always available.
@export var required_flag: String = ""
@export var bob_height: float = 1.5

var player_near: bool = false
var _time: float = 0.0
var _sprite_base_y: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var prompt: Label = $Prompt


func _ready() -> void:
	if item_id == &"":
		push_warning("ItemPickup has no item_id assigned")
		queue_free()
		return
	if GameState.has_item(item_id):
		queue_free()
		return

	var item := ItemCatalog.get_item(item_id)
	if item != null and item.icon != null:
		sprite.texture = item.icon
	_sprite_base_y = sprite.position.y
	prompt.hide()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	GameState.flag_changed.connect(_on_flag_changed)
	_refresh_lock()


func _process(delta: float) -> void:
	if not visible:
		return
	_time += delta
	sprite.position.y = _sprite_base_y + sin(_time * 2.8) * bob_height


func _refresh_lock() -> void:
	var unlocked := required_flag.is_empty() or GameState.has_flag(required_flag)
	visible = unlocked
	set_deferred("monitoring", unlocked)
	if not unlocked:
		player_near = false
		prompt.hide()


func _on_flag_changed(flag: String, value: Variant) -> void:
	if flag == required_flag and value == true:
		_refresh_lock()


func _on_body_entered(body: Node2D) -> void:
	if not visible or not body is Player:
		return
	player_near = true
	prompt.show()


func _on_body_exited(body: Node2D) -> void:
	if not body is Player:
		return
	player_near = false
	prompt.hide()


func _unhandled_input(event: InputEvent) -> void:
	if not player_near or not visible:
		return
	if not event.is_action_pressed("interact") or event.is_echo():
		return
	if get_tree().paused or DialogSystem.is_active:
		return
	get_viewport().set_input_as_handled()
	_pick_up()


func _pick_up() -> void:
	if not player_near:
		return
	player_near = false
	prompt.hide()
	GameState.recover_item(item_id)
	GameState.set_quest_stage(
		"restore_clinic",
		4 if GameState.recovered_count() >= ItemCatalog.TOTAL else 3
	)
	if GameState.recovered_count() >= ItemCatalog.TOTAL:
		GameState.set_flag("equipment_complete", true)
	queue_free()
