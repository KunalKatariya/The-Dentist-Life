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
	if not GameState.has_item(&"curing_light"):
		return [
			"Any light tips?",
			"The tea cart by the clinic. There is a little blue glow under it that is not the lamp. Something is hoarding the curing light and sipping chai.",
			"Something?",
			"Something smoky with very tired eyes. It kept muttering that the light was too loud. Go gently, babe.",
		]
	if not GameState.has_item(&"xray"):
		return [
			"Any X-ray tips?",
			"Down the badminton path. A very small skeleton has set the X-ray board up like a stage. He is showing his bones to anyone who will look.",
			"A skeleton.",
			"A polite one. He bows before he rattles. Copy his flashes and he will hand it over.",
		]
	return [
		"What's next?",
		"Two more pieces are still out there. I am still asking around, babe. The tea is getting cold.",
		"That's it?",
		"For now. I'll keep my ears open.",
	]
