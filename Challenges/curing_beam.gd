class_name CuringBeam extends ChallengeBase
## Catch Gloam's curing light as it sweeps across the tea cart.
##
## The beam swings back and forth over a green target band. Press E or SPACE
## while the beam is inside the band. Catch it three times. Three misses just
## costs an attempt, and the challenge can be retried or skipped as usual.

const LIGHT_TEXTURE := preload("res://Assets_Imported/ui/items/curing_light.png")

@export var beam_speed: float = 2.35
@export var target_half_width: float = 30.0
@export var catches_needed: int = 3
@export var max_misses: int = 3

## Current horizontal position of the beam inside the play area.
var beam_x: float = 0.0
var target_x: float = 184.0
var catches: int = 0
var misses: int = 0

var _phase: float = 0.0
var _flash_time: float = 0.0
var _track: ColorRect
var _target: ColorRect
var _beam: ColorRect
var _lamp: Sprite2D


func _on_attempt_started() -> void:
	catches = 0
	misses = 0
	_flash_time = 0.0
	# Start at the left edge so the first pass gives the player time to read.
	_phase = -PI * 0.5
	beam_x = target_x + sin(_phase) * 128.0
	if _track == null:
		_build_play_area()
	_update_beam()
	set_progress(0.0)
	status_label.text = "Press E or SPACE in the green band — 0 / %d" % catches_needed


func _on_tick(delta: float) -> void:
	_phase += delta * beam_speed
	beam_x = target_x + sin(_phase) * 128.0
	_update_beam()

	if _flash_time > 0.0:
		_flash_time = maxf(0.0, _flash_time - delta)
		_target.color = Color(0.55, 1.0, 0.68, 0.55) if _flash_time > 0.0 else Color(0.36, 0.82, 0.50, 0.35)


func _unhandled_input(event: InputEvent) -> void:
	if not running:
		return
	if event.is_echo():
		return
	if not (event.is_action_pressed("hit") or event.is_action_pressed("interact")):
		return
	get_viewport().set_input_as_handled()
	_try_catch()


## Public for the smoke test: check the beam against the target band.
func _try_catch() -> void:
	if not running:
		return
	if absf(beam_x - target_x) <= target_half_width:
		catches += 1
		set_progress(float(catches) / float(catches_needed) * 100.0)
		_flash_time = 0.18
		status_label.text = "Caught %d / %d!" % [catches, catches_needed]
		if catches >= catches_needed:
			complete()
		else:
			beam_speed = minf(beam_speed + 0.18, 3.4)
	else:
		misses += 1
		status_label.text = "Missed — %d chance%s left" % [
			max_misses - misses,
			"" if max_misses - misses == 1 else "s",
		]
		if misses >= max_misses:
			fail()


func _update_beam() -> void:
	if _beam == null:
		return
	_beam.position = Vector2(beam_x - 5.0, 6.0)
	_lamp.position = Vector2(beam_x, 24.0)


func _build_play_area() -> void:
	_track = ColorRect.new()
	_track.color = Color(0.20, 0.16, 0.22, 1.0)
	_track.position = Vector2(24, 49)
	_track.size = Vector2(320, 4)
	_track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	play_area.add_child(_track)

	_target = ColorRect.new()
	_target.color = Color(0.36, 0.82, 0.50, 0.35)
	_target.position = Vector2(target_x - target_half_width, 8)
	_target.size = Vector2(target_half_width * 2.0, 42)
	_target.mouse_filter = Control.MOUSE_FILTER_IGNORE
	play_area.add_child(_target)

	# Bright edges make the target readable on the dark overlay.
	for x in [target_x - target_half_width, target_x + target_half_width - 2.0]:
		var edge := ColorRect.new()
		edge.color = Color(0.62, 1.0, 0.72, 0.8)
		edge.position = Vector2(x, 8)
		edge.size = Vector2(2, 42)
		edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		play_area.add_child(edge)

	_beam = ColorRect.new()
	_beam.color = Color(1.0, 0.83, 0.42, 0.9)
	_beam.size = Vector2(10, 46)
	_beam.mouse_filter = Control.MOUSE_FILTER_IGNORE
	play_area.add_child(_beam)

	_lamp = Sprite2D.new()
	_lamp.texture = LIGHT_TEXTURE
	_lamp.scale = Vector2(1.7, 1.7)
	play_area.add_child(_lamp)
