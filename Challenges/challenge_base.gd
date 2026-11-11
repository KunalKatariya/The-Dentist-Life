class_name ChallengeBase extends CanvasLayer
## Shared shell for the non-violent robberies.
##
## A challenge pauses the world, shows a small 480x270 friendly minigame, and
## reports success through `finished`. Failure never costs progress: the player
## can retry, and after three failed attempts the challenge can be skipped.

signal finished(success: bool)

const MAX_ATTEMPTS := 3

@export var challenge_title: String = "Challenge"
@export_multiline var instructions: String = ""
@export var duration: float = 20.0
@export_multiline var success_message: String = "Done!"
@export_multiline var failure_message: String = "Not quite. Try again, Doctor."

## Number of attempts started so far.
var attempts: int = 0
var time_left: float = 0.0
var running: bool = false

var _resolved: bool = false
var _player: Node = null

@onready var title_label: Label = $Frame/Margin/VBox/Title
@onready var instructions_label: Label = $Frame/Margin/VBox/Instructions
@onready var play_area: Control = $Frame/Margin/VBox/PlayArea
@onready var progress_bar: ProgressBar = $Frame/Margin/VBox/Progress
@onready var status_label: Label = $Frame/Margin/VBox/Status
@onready var timer_bar: ProgressBar = $Frame/Margin/VBox/TimerBar
@onready var result_panel: PanelContainer = $ResultPanel
@onready var result_label: Label = $ResultPanel/Margin/VBox/Result
@onready var retry_button: Button = $ResultPanel/Margin/VBox/Retry
@onready var skip_button: Button = $ResultPanel/Margin/VBox/Skip
@onready var continue_button: Button = $ResultPanel/Margin/VBox/Continue


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	title_label.text = challenge_title
	instructions_label.text = instructions
	progress_bar.value = 0.0
	timer_bar.value = 100.0
	result_panel.hide()
	retry_button.pressed.connect(_on_retry_pressed)
	skip_button.pressed.connect(_on_skip_pressed)
	continue_button.pressed.connect(_on_continue_pressed)
	_set_player_input(false)
	get_tree().paused = true
	_begin_attempt()


func _exit_tree() -> void:
	# Never leave the game paused if this overlay is removed mid-challenge.
	if not _resolved:
		var tree := get_tree()
		if tree != null:
			tree.paused = false
		_set_player_input(true)


func _process(delta: float) -> void:
	if not running:
		return
	time_left = maxf(0.0, time_left - delta)
	timer_bar.value = (time_left / maxf(duration, 0.01)) * 100.0
	_on_tick(delta)
	if running and time_left <= 0.0:
		fail()


func set_progress(value: float) -> void:
	progress_bar.value = clampf(value, 0.0, 100.0)


# --- Hooks for concrete challenges ----------------------------------------

func _on_attempt_started() -> void:
	pass


func _on_tick(_delta: float) -> void:
	pass


# --- Attempt flow ----------------------------------------------------------

func _begin_attempt() -> void:
	attempts += 1
	time_left = duration
	running = true
	result_panel.hide()
	progress_bar.value = 0.0
	timer_bar.value = 100.0
	status_label.text = ""
	get_viewport().gui_release_focus()
	_on_attempt_started()


func complete() -> void:
	if not running:
		return
	running = false
	_show_result(true)


func fail() -> void:
	if not running:
		return
	running = false
	_show_result(false)


func _show_result(success: bool) -> void:
	retry_button.hide()
	skip_button.hide()
	continue_button.hide()
	if success:
		result_label.text = success_message
		continue_button.show()
		result_panel.show()
		continue_button.grab_focus()
	else:
		result_label.text = failure_message
		retry_button.show()
		if attempts >= MAX_ATTEMPTS:
			skip_button.show()
		result_panel.show()
		retry_button.grab_focus()


func _on_retry_pressed() -> void:
	_begin_attempt()


func _on_skip_pressed() -> void:
	_resolve(true)


func _on_continue_pressed() -> void:
	_resolve(true)


func _resolve(success: bool) -> void:
	if _resolved:
		return
	_resolved = true
	running = false
	result_panel.hide()
	get_tree().paused = false
	_set_player_input(true)
	finished.emit(success)
	queue_free()


func _set_player_input(enabled: bool) -> void:
	if _player == null or not is_instance_valid(_player):
		var scene := get_tree().current_scene
		_player = scene.find_child("Player", true, false) if scene != null else null
	if _player != null and _player.has_method("set_input_enabled"):
		_player.set_input_enabled(enabled)
