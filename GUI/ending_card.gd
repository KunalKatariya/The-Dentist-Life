extends CanvasLayer
## The reopening card shown after the reception bell rings: confetti, a short
## scoreboard of the adventure, and two ways out. It pauses the game while it
## is up and restores the player as soon as it closes.

const VILLAIN_IDS := ["blorb", "wobble", "gloam", "rattle", "mildew", "redtape"]

const FANFARE := [
	{"freq": 523.25, "length": 0.12},
	{"freq": 659.25, "length": 0.12},
	{"freq": 783.99, "length": 0.12},
	{"freq": 1046.50, "length": 0.42},
]
const FANFARE_RATE := 22050.0

@onready var confetti: Control = $Root/Confetti
@onready var stats_label: Label = $Root/Panel/Margin/VBox/Stats
@onready var flavor_label: Label = $Root/Panel/Margin/VBox/Flavor
@onready var stay_button: Button = $Root/Panel/Margin/VBox/Buttons/Stay
@onready var menu_button: Button = $Root/Panel/Margin/VBox/Buttons/Menu

var _open: bool = false
var _leaving: bool = false
var _player: Node = null
var _fanfare_player: AudioStreamPlayer = null


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
	_play_fanfare()
	_set_player_input(false)
	get_tree().paused = true
	stay_button.grab_focus()


func close() -> void:
	if not _open:
		return
	_open = false
	confetti.stop()
	if _fanfare_player != null and is_instance_valid(_fanfare_player):
		_fanfare_player.stop()
	hide()
	get_tree().paused = false
	_set_player_input(true)


## A tiny code-generated fanfare. Keeping it in code avoids a new audio asset
## and it is skipped entirely when the game is running headless.
func _play_fanfare() -> void:
	if AudioServer.get_driver_name() == "Dummy":
		return
	if _fanfare_player != null and is_instance_valid(_fanfare_player):
		_fanfare_player.queue_free()
	var stream := AudioStreamGenerator.new()
	stream.mix_rate = FANFARE_RATE
	stream.buffer_length = 2.0
	_fanfare_player = AudioStreamPlayer.new()
	_fanfare_player.process_mode = Node.PROCESS_MODE_ALWAYS
	_fanfare_player.stream = stream
	add_child(_fanfare_player)
	_fanfare_player.play()
	var playback := _fanfare_player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null:
		return

	var frames := PackedVector2Array()
	var sample_rate := FANFARE_RATE
	for note in FANFARE:
		var length: float = note["length"]
		var freq: float = note["freq"]
		var count := int(length * sample_rate)
		for i in count:
			var t := float(i) / sample_rate
			var attack := minf(1.0, t * 90.0)
			var release := minf(1.0, (length - t) * 24.0)
			var envelope := maxf(0.0, attack * release)
			var wave := (
				sin(TAU * freq * t) * 0.34
				+ sin(TAU * freq * 2.0 * t) * 0.12
				+ sin(TAU * freq * 3.0 * t) * 0.05
			)
			var sample := wave * envelope
			frames.append(Vector2(sample, sample))
		# Short breath between notes.
		for i in int(0.02 * sample_rate):
			frames.append(Vector2.ZERO)
	if playback.can_push_buffer(frames.size()):
		playback.push_buffer(frames)


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
