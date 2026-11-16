@tool
class_name KunalHint extends DialogBranch
## A hub hint that follows the player's current progress instead of being tied
## to one fixed flag. It stays available until the clinic reopens.

func _ready() -> void:
	super._ready()
	if not Engine.is_editor_hint():
		_refresh()


func is_available() -> bool:
	if Engine.is_editor_hint():
		return true
	_refresh()
	return GameState.quest_started() and not GameState.has_flag("clinic_restored")


func _refresh() -> void:
	var lines := hint_lines()
	text = lines[0]

	var labels: Array[DialogText] = []
	for child in get_children():
		if child is DialogText:
			labels.append(child)
	for i in mini(labels.size(), lines.size() - 1):
		labels[i].text = lines[i + 1]


## The hint conversation for the player's current progress. The first line is
## the question the player asks; the rest are Kunal's answers.
func hint_lines() -> Array[String]:
	if GameState.has_flag("clinic_restored") or GameState.get_quest_stage("restore_clinic") >= 5:
		return [
			"How is the clinic?",
			"Open and sparkling, babe. You did it. Now sit down before you find another emergency.",
			"I might just sit.",
			"Good. I will bring chai.",
		]
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
			"The tea lamp on the road just down from Gunika's Dance Academy. There is a little blue glow beside it that is not the lamp. Something is hoarding the curing light and sipping chai.",
			"Something?",
			"Something smoky with very tired eyes. It kept muttering that the light was too loud. Go gently, babe.",
		]
	if not GameState.has_item(&"xray"):
		return [
			"Any X-ray tips?",
			"Down the badminton path. A very small skeleton has set the X-ray board up like a stage. He is showing his bones to anyone who will look.",
			"A skeleton.",
			"A polite one. He bows before he rattles. Catch his tossed bones on the X-ray plate and he will hand it over.",
		]
	if not GameState.has_item(&"sterilizer"):
		return [
			"Any cleaning tips?",
			"The old farm on the west side, by the well. Something soft and green has wrapped the sterilizer in a towel and is calling it a spa.",
			"Something green.",
			"Mildew. Smells like a wet cellar but seems friendly. The pressure gauge is stuck, so be ready to vent it.",
		]
	if not GameState.has_item(&"records"):
		return [
			"Any paperwork tips?",
			"The flower shop north of the square. A stack of paper grew arms and is demanding every file in triplicate. It has the patient records.",
			"Paper with arms.",
			"Redtape. Very serious. Very stamp-happy. Five orthodontistry questions, each harder than the last, and one wrong answer is tolerated.",
		]
	return [
		"What's next?",
		"All six, babe. Even the bell is waiting. Ring it at the clinic reception and tell Priya the clinic is open.",
		"The bell?",
		"The little one on the counter. Ring it and I will bring chai for the reopening.",
	]
