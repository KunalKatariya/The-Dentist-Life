@tool
class_name DialogInteraction
extends Area2D

signal player_interacted
signal finished

@export var enabled: bool = true
var dialog_items: Array[DialogItem] = []
var player_in_area: bool = false

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	body_entered.connect(_on_area_enter)
	body_exited.connect(_on_area_exit)
	for c in get_children():
		if c is DialogItem:
			dialog_items.append(c)

func _on_area_enter(body: Node) -> void:
	print("Player entered dialog area")  # Debug
	if not enabled or dialog_items.is_empty():
		return
	player_in_area = true
	print("Trying to play animation:", animation_player)
	animation_player.play("show")
	print("Current animation now:", animation_player.current_animation)

func _on_area_exit(body: Node) -> void:
	player_in_area = false
	animation_player.play("hide")

func _process(delta: float) -> void:
	if player_in_area and Input.is_action_just_pressed("test"):
		player_interact()

func player_interact() -> void:
	player_interacted.emit()
	print("Player interacted with dialog area")
	DialogSystem.show_dialog(dialog_items)
	DialogSystem.finished.connect(_on_dialog_finished)


func _on_dialog_finished() -> void:
	DialogSystem.finished.disconnect(_on_dialog_finished)
	finished.emit()
	
