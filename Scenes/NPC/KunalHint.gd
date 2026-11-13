@tool
class_name KunalHint extends DialogBranch
## A hub hint that follows the player's current progress instead of being tied
## to one fixed flag. It stays available until the equipment hunt is over.

func _ready() -> void:
	super._ready()
	if not Engine.is_editor_hint():
		_refresh()


func is_available() -> bool:
	if Engine.is_editor_hint():
		return true
	_refresh()
	return GameState.quest_started() and GameState.recovered_count() < ItemCatalog.TOTAL


func _refresh() -> void:
	var lines := _hint_lines()
	text = lines[0]

	var labels: Array[DialogText] = []
	for child in get_children():
		if child is DialogText:
			labels.append(child)
	for i in mini(labels.size(), lines.size() - 1):
		labels[i].text = lines[i + 1]


func _hint_lines() -> Array[String]:
	if not GameState.has_item(&"mirror_set"):
		return [
			"Any clinic tips?",
			"The waiting room. Round green thing. Sleeping on the mirror set. Priya says not to wake it before her tea.",
			"Blorb.",
			"That's the one. Bring the toothbrush.",
		]
	if not GameState.has_item(&"chair"):
		return [
			"Any bakery tips?",
			"Funny you ask. The bakery cart by the clinic keeps wobbling. I thought it was the wind. Then I saw a tooth in a chef hat trying to balance on a dental chair.",
			"A tooth.",
			"A very confident tooth. Be careful, babe. He looked like he had been practicing.",
		]
	return [
		"What's next?",
		"The clinic and the bakery are handled. The rest of town is quiet... for now. Go enjoy Priya's tea.",
		"That's it?",
		"For now. I'll keep my ears open, babe.",
	]
