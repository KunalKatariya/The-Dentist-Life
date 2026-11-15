extends Node

const ENDING_CARD := preload("res://GUI/ending_card.tscn")

@onready var transition = $Transition
@onready var anim_player = $Transition/AnimationPlayer

func _ready():
	# Optional: Fade in when the scene starts
	transition.show()
	anim_player.play("Fade_In")
	_show_ending_card_if_needed()


## If the bell was rung in a previous session but the ending card never made it
## on screen (or the game closed on it), show it now instead of losing the
## closing moment.
func _show_ending_card_if_needed() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_inside_tree():
		return
	if GameState.get_quest_stage("restore_clinic") < 5:
		return
	if GameState.has_flag("ending_seen"):
		return
	if find_child("EndingCard", true, false) != null:
		return
	var card := ENDING_CARD.instantiate()
	add_child(card)
	if card.has_method("open"):
		card.open()
