@tool
class_name DialogInteraction
extends Area2D

signal player_interacted
signal finished

@export var enabled: bool = true
@export var auto_trigger: bool = false  # default false

@export_group("Conditions")
## Interaction only works when this GameState flag is true. Empty = always.
@export var required_flag: String = ""
## Interaction is disabled while this GameState flag is true. Empty = never.
@export var forbidden_flag: String = ""

@export_group("On Finish")
## Flag set when this conversation ends.
@export var set_flag_on_finish: String = ""
## Item id recovered when this conversation ends.
@export var give_item_on_finish: String = ""
## Action routed through ActionRouter when this conversation ends.
@export var action_on_finish: String = ""

var dialog_items: Array[DialogItem] = []
var player_in_area: bool = false
var _dialog_active: bool = false

@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	body_entered.connect(_on_area_enter)
	body_exited.connect(_on_area_exit)
	for c in get_children():
		if c is DialogItem:
			dialog_items.append(c)
	if not DialogSystem.finished.is_connected(_on_dialog_finished):
		DialogSystem.finished.connect(_on_dialog_finished)
	# AUTO-TRIGGER: simulate player entering area
	if auto_trigger and is_available() and not dialog_items.is_empty():
		player_in_area = true
		player_interact()
	pass


## Whether this interaction should currently respond to the player.
func is_available() -> bool:
	if not enabled:
		return false
	if required_flag != "" and not GameState.has_flag(required_flag):
		return false
	if forbidden_flag != "" and GameState.has_flag(forbidden_flag):
		return false
	return true


func _on_area_enter(body: Node) -> void:
	if not is_available() or dialog_items.is_empty():
		return
	player_in_area = true
	animation_player.play("show")


func _on_area_exit(body: Node) -> void:
	player_in_area = false
	animation_player.play("hide")


func _process(delta: float) -> void:
	if player_in_area and is_available() and Input.is_action_just_pressed("interact"):
		player_interact()


func player_interact() -> void:
	if not is_available() or dialog_items.is_empty() or _dialog_active:
		return
	if DialogSystem.is_active:
		return
	_dialog_active = true
	player_interacted.emit()
	DialogSystem.show_dialog(dialog_items)


## Replaces the lines shown by this interaction. Used by NPCs whose dialog
## depends on quest state.
func set_dialog_items(items: Array[DialogItem]) -> void:
	dialog_items = items


func _on_dialog_finished() -> void:
	# DialogSystem.finished fires for every dialog in the game, so ignore it
	# unless this interaction is the one that opened the conversation.
	if not _dialog_active:
		return
	_dialog_active = false
	set_process(true)

	if set_flag_on_finish != "":
		GameState.set_flag(set_flag_on_finish, true)
	if give_item_on_finish != "":
		GameState.recover_item(give_item_on_finish)
	if action_on_finish != "":
		ActionRouter.run(action_on_finish)

	finished.emit()
