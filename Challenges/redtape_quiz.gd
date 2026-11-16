class_name RedtapeQuiz extends ChallengeBase
## Redtape's orthodontic competence review.
##
## Five multiple-choice questions, each harder than the last. Pick an answer
## with the arrow keys and confirm with E or SPACE (the mouse works too). One
## wrong answer is tolerated; a second one sends the form back. Passing the
## review releases the patient records.

const LETTERS: Array[String] = ["A", "B", "C", "D"]

const QUESTIONS := [
	{
		"question": "What does an orthodontist mainly correct?",
		"options": ["Hair growth", "Teeth and bite alignment", "Foot arches", "Ear shape"],
		"answer": 1,
	},
	{
		"question": "What are the small squares glued to each tooth called?",
		"options": ["Brackets", "Crowns", "Fillings", "Veneers"],
		"answer": 0,
	},
	{
		"question": "What is a malocclusion?",
		"options": ["A whitening gel", "A misaligned bite", "A dental chair", "A gum massage"],
		"answer": 1,
	},
	{
		"question": "Which wire runs through the brackets to guide teeth?",
		"options": ["Floss", "A bridge", "An archwire", "A veneer"],
		"answer": 2,
	},
	{
		"question": "What does a palatal expander widen?",
		"options": ["The lower jaw", "The tongue", "The upper jaw", "The sinuses"],
		"answer": 2,
	},
]

@export var max_mistakes: int = 2
## How long the APPROVED / REJECTED stamp stays up before the next question.
@export var answer_delay: float = 0.75

## Live state. Public so the smoke test can answer without fake mouse events.
var question_index: int = 0
var mistakes: int = 0
var correct_count: int = 0
var selected: int = 0
var shuffled: Array[int] = []
var option_buttons: Array[Button] = []

var _pending_advance: bool = false
var _wait_time: float = 0.0
var _style_normal: StyleBoxFlat
var _style_selected: StyleBoxFlat
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	super._ready()


func _on_attempt_started() -> void:
	question_index = 0
	mistakes = 0
	correct_count = 0
	selected = 0
	_pending_advance = false
	_wait_time = 0.0
	_build_play_area()
	_build_styles()
	_load_question()


func _on_tick(delta: float) -> void:
	if not _pending_advance:
		return
	_wait_time -= delta
	if _wait_time <= 0.0:
		_pending_advance = false
		_advance()


func _unhandled_input(event: InputEvent) -> void:
	if not running or _pending_advance or event.is_echo():
		return
	var handled := true
	if event.is_action_pressed("left") or event.is_action_pressed("ui_left"):
		selected = (selected + 3) % 4
	elif event.is_action_pressed("right") or event.is_action_pressed("ui_right"):
		selected = (selected + 1) % 4
	elif event.is_action_pressed("up") or event.is_action_pressed("ui_up"):
		selected = (selected + 2) % 4
	elif event.is_action_pressed("down") or event.is_action_pressed("ui_down"):
		selected = (selected + 2) % 4
	elif (
		event.is_action_pressed("interact")
		or event.is_action_pressed("hit")
		or event.is_action_pressed("ui_accept")
	):
		choose(selected)
	else:
		handled = false
	if handled:
		get_viewport().set_input_as_handled()
		_apply_selection()


## Public for the smoke test: pick option `index` (0-3) right now.
func choose(index: int) -> void:
	if not running or _pending_advance:
		return
	if index < 0 or index >= option_buttons.size():
		return

	var correct := correct_index()
	if index == correct:
		correct_count += 1
		status_label.text = "APPROVED. Stamped and filed."
	elif mistakes + 1 >= max_mistakes:
		mistakes += 1
		status_label.text = "REJECTED — the answer was %s." % LETTERS[correct]
		fail()
		return
	else:
		mistakes += 1
		status_label.text = "REJECTED — the answer was %s." % LETTERS[correct]

	question_index += 1
	set_progress(float(question_index) / float(QUESTIONS.size()) * 100.0)
	if answer_delay <= 0.0:
		_advance()
	else:
		_pending_advance = true
		_wait_time = answer_delay
		_set_buttons_disabled(true)


## Position of the correct answer in the shuffled button order.
func correct_index() -> int:
	if question_index >= QUESTIONS.size():
		return -1
	var answer: int = QUESTIONS[question_index]["answer"]
	return shuffled.find(answer)


func question_total() -> int:
	return QUESTIONS.size()


func _advance() -> void:
	_set_buttons_disabled(false)
	if question_index >= QUESTIONS.size():
		set_progress(100.0)
		status_label.text = "All five forms approved. Redtape is satisfied."
		complete()
		return
	_load_question()


func _load_question() -> void:
	if question_index >= QUESTIONS.size():
		_advance()
		return
	var question: Dictionary = QUESTIONS[question_index]
	_shuffle_options()
	instructions_label.text = question["question"]
	for i in option_buttons.size():
		option_buttons[i].text = "%s. %s" % [
			LETTERS[i],
			question["options"][shuffled[i]],
		]
		option_buttons[i].disabled = false
	selected = 0
	_apply_selection()
	set_progress(float(question_index) / float(QUESTIONS.size()) * 100.0)
	status_label.text = "Question %d / %d — arrows to choose, E or SPACE to stamp." % [
		question_index + 1,
		QUESTIONS.size(),
	]


func _shuffle_options() -> void:
	shuffled = [0, 1, 2, 3]
	for i in range(shuffled.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var swap: int = shuffled[i]
		shuffled[i] = shuffled[j]
		shuffled[j] = swap


func _set_buttons_disabled(disabled: bool) -> void:
	for button in option_buttons:
		button.disabled = disabled


func _apply_selection() -> void:
	for i in option_buttons.size():
		var button := option_buttons[i]
		var is_selected := i == selected
		button.add_theme_stylebox_override(
			"normal",
			_style_selected if is_selected else _style_normal,
		)
		button.add_theme_stylebox_override(
			"hover",
			_style_selected if is_selected else _style_normal,
		)
		button.add_theme_stylebox_override(
			"pressed",
			_style_selected if is_selected else _style_normal,
		)
		button.add_theme_color_override(
			"font_color",
			Color(1.0, 0.92, 0.62, 1.0) if is_selected else Color(0.92, 0.90, 0.84, 1.0),
		)


func _on_option_pressed(index: int) -> void:
	choose(index)


func _build_play_area() -> void:
	for child in play_area.get_children():
		child.queue_free()
	option_buttons.clear()

	var width := play_area.size.x
	if width <= 50.0:
		width = 368.0
	var button_width := (width - 10.0) * 0.5
	var button_height := 26.0
	for i in 4:
		var button := Button.new()
		button.focus_mode = Control.FOCUS_NONE
		button.add_theme_font_size_override("font_size", 8)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.clip_text = true
		button.position = Vector2(
			3.0 + float(i % 2) * (button_width + 4.0),
			3.0 + float(i / 2) * (button_height + 3.0),
		)
		button.size = Vector2(button_width, button_height)
		button.pressed.connect(_on_option_pressed.bind(i))
		play_area.add_child(button)
		option_buttons.append(button)


func _build_styles() -> void:
	if _style_normal != null:
		return
	_style_normal = StyleBoxFlat.new()
	_style_normal.bg_color = Color(0.19, 0.17, 0.24, 0.96)
	_style_normal.border_width_left = 1
	_style_normal.border_width_top = 1
	_style_normal.border_width_right = 1
	_style_normal.border_width_bottom = 1
	_style_normal.border_color = Color(0.38, 0.34, 0.44, 1.0)
	_style_normal.corner_radius_top_left = 2
	_style_normal.corner_radius_top_right = 2
	_style_normal.corner_radius_bottom_right = 2
	_style_normal.corner_radius_bottom_left = 2

	_style_selected = StyleBoxFlat.new()
	_style_selected.bg_color = Color(0.44, 0.30, 0.18, 0.98)
	_style_selected.border_width_left = 2
	_style_selected.border_width_top = 2
	_style_selected.border_width_right = 2
	_style_selected.border_width_bottom = 2
	_style_selected.border_color = Color(0.96, 0.78, 0.36, 1.0)
	_style_selected.corner_radius_top_left = 2
	_style_selected.corner_radius_top_right = 2
	_style_selected.corner_radius_bottom_right = 2
	_style_selected.corner_radius_bottom_left = 2
