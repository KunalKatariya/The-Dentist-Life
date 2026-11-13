class_name XrayMemory extends ChallengeBase
## Repeat Rattle's bone flashes.
##
## Four panels flash a short direction sequence. Repeat it with the arrow keys
## or WASD. One wrong flash replays the sequence; a second one ends the attempt.
## Two rounds (three flashes, then four) win the X-ray machine.

const DIRECTIONS: Array[String] = ["left", "up", "down", "right"]
const LABELS := {
	"left": "<",
	"up": "^",
	"down": "v",
	"right": ">",
}

@export var rounds: int = 2
@export var base_length: int = 3
@export var step_delay: float = 0.62
@export var lit_time: float = 0.34
@export var max_mistakes: int = 2

## Current sequence and the player's place in it. Public for the smoke test.
var sequence: Array[String] = []
var round_index: int = 0
var input_index: int = 0
var mistakes: int = 0
var showing: bool = true

var _show_timer: float = 0.0
var _panels := {}
var _flash_time: float = 0.0
var _flash_dir: String = ""
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	super._ready()


func _on_attempt_started() -> void:
	round_index = 0
	mistakes = 0
	_flash_time = 0.0
	_flash_dir = ""
	if _panels.is_empty():
		_build_play_area()
	_start_round()


func _on_tick(delta: float) -> void:
	if _flash_time > 0.0:
		_flash_time = maxf(0.0, _flash_time - delta)
		if _flash_time <= 0.0:
			_set_lit(-1)

	if showing:
		_show_timer += delta
		var index := int(_show_timer / step_delay)
		var lit := index < sequence.size() and (_show_timer - index * step_delay) < lit_time
		_set_lit(index if lit else -1)
		if _show_timer >= sequence.size() * step_delay + 0.25:
			showing = false
			_set_lit(-1)
			input_index = 0
			status_label.text = "Your turn — repeat %d flashes." % sequence.size()
		return

	status_label.text = "Your turn — %d / %d" % [input_index, sequence.size()]


func _unhandled_input(event: InputEvent) -> void:
	if not running or showing or event.is_echo():
		return
	var direction := ""
	if event.is_action_pressed("left") or event.is_action_pressed("ui_left"):
		direction = "left"
	elif event.is_action_pressed("up") or event.is_action_pressed("ui_up"):
		direction = "up"
	elif event.is_action_pressed("down") or event.is_action_pressed("ui_down"):
		direction = "down"
	elif event.is_action_pressed("right") or event.is_action_pressed("ui_right"):
		direction = "right"
	if direction.is_empty():
		return
	get_viewport().set_input_as_handled()
	_handle_input(direction)


## Public for the smoke test so both rounds can be driven without fake events.
func _handle_input(direction: String) -> void:
	if not running or showing:
		return
	if input_index >= sequence.size():
		return

	if direction == sequence[input_index]:
		input_index += 1
		_flash_dir = direction
		_flash_time = 0.12
		_set_lit(input_index - 1, true)
		if input_index >= sequence.size():
			round_index += 1
			set_progress(float(round_index) / float(rounds) * 100.0)
			if round_index >= rounds:
				complete()
			else:
				status_label.text = "Good! One more round."
				_start_round()
	else:
		mistakes += 1
		if mistakes >= max_mistakes:
			fail()
		else:
			status_label.text = "Wrong flash — watch it again."
			_start_round()


func _start_round() -> void:
	sequence.clear()
	var length := base_length + round_index
	for i in length:
		sequence.append(DIRECTIONS[_rng.randi_range(0, DIRECTIONS.size() - 1)])
	showing = true
	_show_timer = 0.0
	input_index = 0
	_flash_time = 0.0
	_flash_dir = ""
	_set_lit(-1)
	status_label.text = "Watch the bone flashes…"
	set_progress(float(round_index) / float(rounds) * 100.0)


func _set_lit(index: int, force_dir: bool = false) -> void:
	for direction in _panels:
		var panel: ColorRect = _panels[direction]
		var lit := false
		if force_dir and direction == _flash_dir:
			lit = true
		elif not force_dir and index >= 0 and index < sequence.size():
			lit = sequence[index] == direction
		panel.color = Color(0.48, 0.92, 0.82, 1.0) if lit else Color(0.19, 0.17, 0.28, 1.0)


func _build_play_area() -> void:
	var x := 10.0
	for direction in DIRECTIONS:
		var panel := ColorRect.new()
		panel.color = Color(0.19, 0.17, 0.28, 1.0)
		panel.position = Vector2(x, 9)
		panel.size = Vector2(78, 44)
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		play_area.add_child(panel)

		var label := Label.new()
		label.text = LABELS[direction]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 20)
		label.add_theme_color_override("font_color", Color(0.93, 0.95, 0.90, 1.0))
		label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_child(label)

		_panels[direction] = panel
		x += 84.0
