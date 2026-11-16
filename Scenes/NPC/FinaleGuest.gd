class_name FinaleGuest extends NPC
## A friendly face who only turns up for reopening day. Kunal waits in the
## clinic once all six pieces of equipment are home, so the bell finale has
## someone to hold the banner.

@export var minimum_items: int = 6


func _ready() -> void:
	super._ready()
	_refresh_visibility()
	GameState.item_recovered.connect(_on_item_recovered)
	GameState.game_loaded.connect(_refresh_visibility)


func _on_item_recovered(_item_id: StringName) -> void:
	_refresh_visibility()


func _refresh_visibility() -> void:
	var show_guest := GameState.recovered_count() >= minimum_items
	visible = show_guest
	set_process(show_guest)
	# Keep the prompt and conversation dormant until Kunal is actually here.
	for child in get_children():
		if child is DialogInteraction:
			child.enabled = show_guest
