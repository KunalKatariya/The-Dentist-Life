@tool
class_name DialogBranch extends DialogItem

@export var text : String = "ok..."
@export var action_name: String = "" # e.g. "go_to_badminton"
## Branch only appears when this GameState flag is true. Empty = no requirement.
@export var required_flag: String = ""
## Branch is hidden when this GameState flag is true. Empty = never hidden.
@export var forbidden_flag: String = ""

var dialog_items : Array[DialogItem]

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	for c in get_children():
		if c is DialogItem:
			dialog_items.append(c)
	pass


## Whether this branch should be offered to the player right now.
func is_available() -> bool:
	if Engine.is_editor_hint():
		return true
	if required_flag != "" and not GameState.has_flag(required_flag):
		return false
	if forbidden_flag != "" and GameState.has_flag(forbidden_flag):
		return false
	return true
