extends Node
## Central dispatcher for dialog branch actions.
##
## Dialog choices carry an action_name. Instead of writing directly into the
## current scene root (which breaks in any scene without that variable), the
## action goes through here. Actions that belong to no specific scene are
## handled immediately; everything else is emitted so the current scene can
## react to it.

signal action_requested(action_name: String)


func run(action_name: String) -> void:
	if action_name.is_empty():
		return
	match action_name:
		"start_quest":
			GameState.set_quest_stage("restore_clinic", 1)
		"give_toothbrush":
			GameState.set_flag("got_toothbrush")
			GameState.set_quest_stage("restore_clinic", 2)
		_:
			action_requested.emit(action_name)
