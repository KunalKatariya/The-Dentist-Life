class_name ClinicNpc extends NPC
## A clinic NPC whose dialog is built from current quest state, so the same
## character can say different things before and after key events.

const PLAYER_INFO := preload("res://Scenes/NPC/npc_player.tres")
const PRIYA_INFO := preload("res://Scenes/NPC/priya.tres")
const MEHTA_INFO := preload("res://Scenes/NPC/mehta.tres")

@export_enum("priya", "mehta") var dialog_key: String = "priya"
## Automatically start the first conversation shortly after the scene loads.
@export var auto_greet: bool = false
@export var greet_delay: float = 1.6

var _owned_lines: Array[DialogItem] = []


func _ready() -> void:
	super._ready()
	var interaction := _interaction()
	if interaction and not interaction.player_interacted.is_connected(_refresh_dialog):
		interaction.player_interacted.connect(_refresh_dialog)
	_refresh_dialog()
	if auto_greet:
		_start_greet_timer()


func _interaction() -> DialogInteraction:
	return get_node_or_null("DialogInteraction") as DialogInteraction


func _refresh_dialog() -> void:
	var interaction := _interaction()
	if interaction == null:
		return
	for line in _owned_lines:
		if is_instance_valid(line):
			line.queue_free()
	_owned_lines.clear()
	var lines := _build_dialog()
	for line in lines:
		# Parent the lines so they are cleaned up with the NPC instead of
		# lingering as orphan nodes.
		add_child(line)
		_owned_lines.append(line)
	interaction.set_dialog_items(lines)


func _build_dialog() -> Array[DialogItem]:
	match dialog_key:
		"mehta":
			return _mehta_dialog()
		_:
			if not GameState.quest_started():
				return _priya_first_dialog()
			return _priya_repeat_dialog()


func _npc_info() -> NPCResource:
	if npc_resource != null:
		return npc_resource
	return PRIYA_INFO if dialog_key == "priya" else MEHTA_INFO


func _line(text: String, player: bool = false) -> DialogText:
	var line := DialogText.new()
	line.npc_info = PLAYER_INFO if player else _npc_info()
	line.text = text
	return line


func _priya_first_dialog() -> Array[DialogItem]:
	var out: Array[DialogItem] = []
	out.append(_line("Doctor! Thank god. Sit down. Actually don't — someone stole all the chairs."))
	out.append(_line("Someone robbed the clinic?", true))
	out.append(_line("Overnight. They left the waiting-room magazines. Honestly, those were the most valuable things in the building."))
	out.append(_line("Six pieces of equipment. I made a list. I also made tea. The tea is the only thing that survived."))
	out.append(_line("Who does this?", true))
	out.append(_line("A sugar creature, I think. Small. Round. Smells like a birthday party. It left a trail of icing to the door."))
	out.append(_line("Here — a detective notebook and your travel toothbrush. You're going to need both."))
	out.append(_line("The mirror set is still here, by the way. Something round and green is asleep on it. Please don't wake it before I finish my tea."))
	out.append(_line("I'm going to brush a sugar creature.", true))
	out.append(_line("That's the most dentist thing you've ever said."))
	return out


func _priya_repeat_dialog() -> Array[DialogItem]:
	var out: Array[DialogItem] = []
	if not GameState.has_item(&"mirror_set"):
		out.append(_line("Any luck? The waiting room is getting restless. Mr. Mehta has named his toothache Steve."))
		out.append(_line("Leave Mr. Mehta alone — he's only here for Steve. That round green thing is still asleep by the right-hand chair. It's on the mirror set."))
		out.append(_line("You're enjoying this.", true))
		out.append(_line("I'm enjoying the tea. The rest is a bonus."))
	elif GameState.recovered_count() < ItemCatalog.TOTAL:
		var count := GameState.recovered_count()
		if count <= 1:
			out.append(_line("One down! The exam station looks almost usable. Almost."))
		else:
			out.append(_line("%d down. The clinic is starting to look like a clinic again." % count))
		if GameState.has_item(&"chair"):
			out.append(_line("Wobble left a note about the chair. It says it was 'warm and well loved'. I'm choosing to find that sweet."))
		out.append(_line("Try the village next. Kunal has been pacing outside like a very handsome compass."))
		out.append(_line("He's going to want a title.", true))
		out.append(_line("Give him 'Chief Moral Support'. He'll cry."))
	else:
		out.append(_line("All six. Doctor, I don't know whether to hug you or update your will."))
		out.append(_line("The waiting room wants a reopening day. Mr. Mehta has already written a speech for Steve."))
		out.append(_line("Of course he has.", true))
	return out


func _mehta_dialog() -> Array[DialogItem]:
	var out: Array[DialogItem] = []
	out.append(_line("Doctor, I've had this toothache for three days. I named it. His name is Steve."))
	out.append(_line("Hello, Steve.", true))
	out.append(_line("He's not friendly. He throbs when I drink water. He throbs when I think about water."))
	out.append(_line("I heard the clinic was robbed. Should I come back later?"))
	out.append(_line("No. Stay. If I can find the equipment, I can fix Steve.", true))
	out.append(_line("You're going to fight a sugar monster with a toothbrush, aren't you?"))
	out.append(_line("Yes.", true))
	out.append(_line("This is the best waiting room I've ever been in."))
	if GameState.has_flag("villain_blorb_cleared"):
		out.append(_line("Also, the blob by the door is gone. Steve says the waiting room feels roomier. Steve is very brave."))
	elif GameState.has_item(&"mirror_set"):
		out.append(_line("Also, I saw the blob by the door. It waved at me. Steve did not wave back."))
	else:
		out.append(_line("Also, that round green blob by the right chair has been staring at me. I think it wants my tooth."))
	return out


func _start_greet_timer() -> void:
	# The quest begins with this conversation, even for saves that arrived out
	# of order before the intro was completed.
	if GameState.quest_started():
		return
	var timer := Timer.new()
	timer.wait_time = greet_delay
	timer.one_shot = true
	add_child(timer)
	timer.timeout.connect(_on_greet_timeout)
	timer.start()


func _on_greet_timeout() -> void:
	if GameState.quest_started():
		return
	var interaction := _interaction()
	if interaction == null:
		return
	interaction.player_interact()


## Grant the notebook and toothbrush whichever way the first Priya dialog was
## opened: automatically on arrival or by the player pressing E.
func _on_interaction_finished() -> void:
	if dialog_key == "priya" and not GameState.quest_started():
		_grant_intro_rewards()


func _grant_intro_rewards() -> void:
	if GameState.quest_started():
		return
	GameState.set_flag("met_clerk", true)
	GameState.set_flag("got_notebook", true)
	ActionRouter.run("start_quest")
	ActionRouter.run("give_toothbrush")
