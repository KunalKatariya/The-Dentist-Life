class_name ChairBalance extends ChallengeBase
## Keep Wobble's perch upright.
##
## The stolen dental chair leans one way, then the other. Counter the lean with
## A/D or the arrow keys and keep it upright until the timer runs out. The
## challenge is harmless: tipping over only means another go.

const CHAIR_TEXTURE := preload("res://Assets_Imported/ui/items/chair.png")
const WOBBLE_TEXTURE := preload("res://Assets_Imported/villains/wobble.png")

@export var drift_strength: float = 0.95
@export var counter_strength: float = 1.9
@export var tilt_limit: float = 1.0
@export var drift_change_interval: float = 0.65

## Current lean. Negative is left, positive is right.
var tilt: float = 0.0

var _drift: float = 0.0
var _direction: float = 1.0
var _next_drift: float = 0.0
var _chair: Sprite2D
var _wobble: Sprite2D
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	super._ready()


func _on_attempt_started() -> void:
	tilt = 0.0
	_drift = 0.0
	_next_drift = drift_change_interval
	_direction = -1.0 if _rng.randf() < 0.5 else 1.0
	set_progress(0.0)
	if _chair == null:
		_build_play_area()
	_chair.rotation = 0.0
	_wobble.rotation = 0.0
	status_label.text = "Hold it steady!"


func _on_tick(delta: float) -> void:
	_next_drift -= delta
	if _next_drift <= 0.0:
		_next_drift = drift_change_interval
		_direction = -1.0 if _rng.randf() < 0.5 else 1.0

	# The chair leans toward its current direction. The player can always push
	# back harder than the lean, so every failure is a reaction mistake, not a
	# lost cause.
	_drift = move_toward(_drift, _direction * drift_strength, delta * 1.5)
	tilt += (_drift + _input_direction() * counter_strength) * delta

	if absf(tilt) >= tilt_limit:
		_chair.rotation = signf(tilt) * 0.8
		_wobble.rotation = signf(tilt) * 0.8
		fail()
		return

	_chair.rotation = tilt * 0.55
	_wobble.rotation = tilt * 0.55
	set_progress((1.0 - time_left / maxf(duration, 0.01)) * 100.0)
	status_label.text = "Hold it steady — %d seconds left" % ceili(time_left)

	if time_left <= 0.0:
		complete()


func _input_direction() -> float:
	var direction := 0.0
	if Input.is_action_pressed("left") or Input.is_action_pressed("ui_left"):
		direction -= 1.0
	if Input.is_action_pressed("right") or Input.is_action_pressed("ui_right"):
		direction += 1.0
	return direction


func _build_play_area() -> void:
	var floor_line := ColorRect.new()
	floor_line.color = Color(0.32, 0.23, 0.19, 1.0)
	floor_line.position = Vector2(84, 53)
	floor_line.size = Vector2(200, 3)
	floor_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	play_area.add_child(floor_line)

	var shadow := ColorRect.new()
	shadow.color = Color(0.08, 0.06, 0.09, 0.45)
	shadow.position = Vector2(166, 48)
	shadow.size = Vector2(36, 6)
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	play_area.add_child(shadow)

	_chair = Sprite2D.new()
	_chair.texture = CHAIR_TEXTURE
	_chair.scale = Vector2(3.2, 3.2)
	_chair.offset = Vector2(0, -8)
	_chair.position = Vector2(184, 52)
	play_area.add_child(_chair)

	_wobble = Sprite2D.new()
	_wobble.texture = WOBBLE_TEXTURE
	_wobble.scale = Vector2(0.42, 0.42)
	_wobble.offset = Vector2(0, -32)
	_wobble.position = Vector2(184, 29)
	_wobble.z_index = 1
	play_area.add_child(_wobble)
