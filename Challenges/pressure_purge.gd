class_name PressurePurge extends ChallengeBase
## Vent Mildew's over-pressurised sterilizer.
##
## The pressure needle sweeps across the gauge. Press E or SPACE while it is
## inside the green band. Five vents win, but the band shrinks and the needle
## speeds up after every success. Two misses end the attempt; retry and skip
## work exactly like the other robberies.

const GAUGE_LEFT := 20.0
const GAUGE_RIGHT := 340.0
const GAUGE_CENTER := 180.0
const GAUGE_AMPLITUDE := 160.0

@export var needle_speed: float = 3.0
@export var max_needle_speed: float = 4.4
@export var target_half_width: float = 24.0
@export var min_target_half_width: float = 13.0
@export var catches_needed: int = 5
@export var max_misses: int = 2

## Current needle position. Public so the smoke test can drive the gauge.
var needle_x: float = GAUGE_LEFT
var target_x: float = GAUGE_CENTER
var catches: int = 0
var misses: int = 0

var _phase: float = 0.0
var _flash_time: float = 0.0
var _track: ColorRect
var _target: ColorRect
var _needle: ColorRect
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	super._ready()


func _on_attempt_started() -> void:
	catches = 0
	misses = 0
	_flash_time = 0.0
	needle_speed = 3.0
	target_half_width = 24.0
	target_x = GAUGE_CENTER
	# Begin at the left end of the sweep so the first pass is readable.
	_phase = -PI * 0.5
	needle_x = GAUGE_LEFT
	if _track == null:
		_build_play_area()
	_update_needle()
	set_progress(0.0)
	status_label.text = "Press E or SPACE in the green band — 0 / %d" % catches_needed


func _on_tick(delta: float) -> void:
	_phase += delta * needle_speed
	needle_x = GAUGE_CENTER + sin(_phase) * GAUGE_AMPLITUDE
	_update_needle()

	if _flash_time > 0.0:
		_flash_time = maxf(0.0, _flash_time - delta)
		if _target != null:
			_target.color = (
				Color(0.55, 1.0, 0.68, 0.55)
				if _flash_time > 0.0
				else Color(0.36, 0.82, 0.50, 0.30)
			)


func _unhandled_input(event: InputEvent) -> void:
	if not running or event.is_echo():
		return
	if not (event.is_action_pressed("hit") or event.is_action_pressed("interact")):
		return
	get_viewport().set_input_as_handled()
	_try_vent()


## Public for the smoke test: check the needle against the pressure band.
func _try_vent() -> void:
	if not running:
		return
	if absf(needle_x - target_x) <= target_half_width:
		catches += 1
		set_progress(float(catches) / float(catches_needed) * 100.0)
		_flash_time = 0.18
		if catches >= catches_needed:
			status_label.text = "Pressure normal. The lid pops open!"
			complete()
		else:
			needle_speed = minf(needle_speed + 0.24, max_needle_speed)
			target_half_width = maxf(min_target_half_width, target_half_width - 2.0)
			target_x = _rng.randf_range(70.0, 290.0)
			_update_target()
			status_label.text = "Vent %d / %d — the gauge is settling." % [
				catches,
				catches_needed,
			]
	else:
		misses += 1
		var left := max_misses - misses
		status_label.text = "Missed — %d chance%s left" % [
			left,
			"" if left == 1 else "s",
		]
		if misses >= max_misses:
			fail()


func _update_needle() -> void:
	if _needle == null:
		return
	_needle.position = Vector2(needle_x - 1.0, 4.0)


func _update_target() -> void:
	if _target == null:
		return
	_target.position = Vector2(target_x - target_half_width, 8.0)
	_target.size = Vector2(target_half_width * 2.0, 40.0)
	for edge in _edges:
		var side: float = edge["side"]
		var rect: ColorRect = edge["rect"]
		rect.position = Vector2(
			target_x + side * target_half_width - 1.0,
			8.0,
		)


var _edges: Array[Dictionary] = []


func _build_play_area() -> void:
	# Gauge face.
	var face := ColorRect.new()
	face.color = Color(0.12, 0.14, 0.16, 1.0)
	face.position = Vector2(GAUGE_LEFT, 8.0)
	face.size = Vector2(GAUGE_RIGHT - GAUGE_LEFT, 40.0)
	face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	play_area.add_child(face)

	# Pressure ticks.
	for x in [GAUGE_LEFT, 100.0, GAUGE_CENTER, 260.0, GAUGE_RIGHT]:
		var tick := ColorRect.new()
		tick.color = Color(0.34, 0.36, 0.34, 1.0)
		tick.position = Vector2(x - 1.0, 8.0)
		tick.size = Vector2(2.0, 8.0)
		tick.mouse_filter = Control.MOUSE_FILTER_IGNORE
		play_area.add_child(tick)

	_target = ColorRect.new()
	_target.color = Color(0.36, 0.82, 0.50, 0.30)
	_target.position = Vector2(target_x - target_half_width, 8.0)
	_target.size = Vector2(target_half_width * 2.0, 40.0)
	_target.mouse_filter = Control.MOUSE_FILTER_IGNORE
	play_area.add_child(_target)

	_edges.clear()
	for side in [-1.0, 1.0]:
		var edge := ColorRect.new()
		edge.color = Color(0.62, 1.0, 0.72, 0.85)
		edge.position = Vector2(target_x + side * target_half_width - 1.0, 8.0)
		edge.size = Vector2(2.0, 40.0)
		edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		play_area.add_child(edge)
		_edges.append({"side": side, "rect": edge})

	_track = ColorRect.new()
	_track.color = Color(0.26, 0.29, 0.27, 1.0)
	_track.position = Vector2(GAUGE_LEFT, 47.0)
	_track.size = Vector2(GAUGE_RIGHT - GAUGE_LEFT, 3.0)
	_track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	play_area.add_child(_track)

	_needle = ColorRect.new()
	_needle.color = Color(1.0, 0.52, 0.34, 0.95)
	_needle.size = Vector2(3.0, 44.0)
	_needle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	play_area.add_child(_needle)
