extends CanvasLayer
## The reopening card shown after the reception bell rings: confetti, a short
## scoreboard of the adventure, and two ways out. It pauses the game while it
## is up and restores the player as soon as it closes.

const VILLAIN_IDS := ["blorb", "wobble", "gloam", "rattle"]

@onready var confetti: Control = $Root/Confetti
@onready var stats_label: Label = $Root/Panel/Margin/VBox/Stats
@onready var flavor_label: Label = $Root/Panel/Margin/VBox/Flavor
@onready var stay_button: Button = $Root/Panel/Margin/VBox/Buttons/Stay
@onready var menu_button: Button = $Root/Panel/Margin/VBox/Buttons/Menu

var _open: bool = false
var _leaving: bool = false
var _player: Node = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	stay_button.pressed.connect(close)
	menu_button.pressed.connect(_go_to_menu)


func is_open() -> bool:
	return _open


## Show the card, mark the ending as seen and take control of the game.
func open() -> void:
	if _open or _leaving:
		return
	_open = true
	GameState.set_flag("ending_seen", true)
	_refresh_stats()
	_show_buttons(true)
	if GameHUD != null:
		GameHUD.clear_toast()
	show()
	confetti.start()
	_set_player_input(false)
	get_tree().paused = true
	stay_button.grab_focus()


func close() -> void:
	if not _open:
		return
	_open = false
	confetti.stop()
	hide()
	get_tree().paused = false
	_set_player_input(true)


func _refresh_stats() -> void:
	var villains := 0
	for id in VILLAIN_IDS:
		if GameState.has_flag("villain_%s_cleared" % id):
			villains += 1
	var equipment := GameState.recovered_count()
	stats_label.text = "\n".join([
		"Equipment returned     %d / %d" % [equipment, ItemCatalog.TOTAL],
		"Villains befriended    %d / %d" % [villains, VILLAIN_IDS.size()],
		"Stickers collected     %d" % GameState.stickers.size(),
	])
	if equipment >= ItemCatalog.TOTAL and villains >= VILLAIN_IDS.size():
		flavor_label.text = "Priya has put the kettle on. Mr. Mehta has booked Steve in for a cleaning."
	else:
		flavor_label.text = "The waiting room is full and the kettle is on. Welcome back, Doctor."


func _go_to_menu() -> void:
	if not _open or _leaving:
		return
	_leaving = true
	_show_buttons(false)
	confetti.stop()
	GameState.save_current_scene_state()
	get_tree().paused = false
	SceneRouter.clear_spawn()
	SceneRouter.go("menu")


func _show_buttons(enabled: bool) -> void:
	stay_button.disabled = not enabled
	menu_button.disabled = not enabled


func _set_player_input(enabled: bool) -> void:
	if _player == null or not is_instance_valid(_player):
		var scene := get_tree().current_scene
		_player = scene.find_child("Player", true, false) if scene != null else null
	if _player != null and _player.has_method("set_input_enabled"):
		_player.set_input_enabled(enabled)
