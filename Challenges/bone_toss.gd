class_name BoneToss extends ChallengeBase
## Catch Rattle's bones on the X-ray plate.
##
## Rattle tosses his spare bones across the stage. Move the plate with A/D or
## the arrow keys and catch eight of them before the music stops. Golden bones
## count double. Drop three and the act is over — retry and skip work as usual.

const PLAY_WIDTH := 368.0
const PLAY_HEIGHT := 62.0
const TRAY_Y := 53.0
const TRAY_HALF := 24.0
const BONE_COLOR := Color(0.94, 0.93, 0.86, 1.0)
const GOLD_COLOR := Color(0.98, 0.80, 0.34, 1.0)
const PLATE_COLOR := Color(0.52, 0.72, 0.80, 1.0)
const PLATE_DARK := Color(0.20, 0.30, 0.38, 1.0)
const BACKGROUND := Color(0.06, 0.07, 0.10, 1.0)

@export var catches_needed: int = 8
@export var max_drops: int = 3
@export var tray_speed: float = 225.0
@export var spawn_interval: float = 0.86
@export var min_spawn_interval: float = 0.44

## Live state. Public so the smoke test can drive the stage without input.
var tray_x: float = PLAY_WIDTH * 0.5
var catches: int = 0
var drops: int = 0
var bones: Array = []

var _spawned: int = 0
var _spawn_timer: float = 0.0
var _tray: Polygon2D
var _tray_rim: Polygon2D
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	super._ready()


func _on_attempt_started() -> void:
	catches = 0
	drops = 0
	_spawned = 0
	_spawn_timer = 0.45
	tray_x = _width() * 0.5
	_build_play_area()
	set_progress(0.0)
	status_label.text = "Catch %d bones — A/D or arrows to move" % catches_needed
	# A gentle first bone so the player can find the plate.
	_spawn_bone(_width() * 0.5, false)


func _on_tick(delta: float) -> void:
	if _tray == null:
		_build_play_area()
	_move_tray(delta)
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		var interval := maxf(min_spawn_interval, spawn_interval - float(_spawned) * 0.015)
		_spawn_timer = interval
		_spawned += 1
		var golden := _spawned % 5 == 0
		_spawn_bone(_rng.randf_range(26.0, _width() - 26.0), golden)
	_tick_bones(delta)


func _unhandled_input(event: InputEvent) -> void:
	if not running or event.is_echo():
		return
	if not (event.is_action_pressed("interact") or event.is_action_pressed("hit")):
		return
	# Keep E/SPACE from leaking into the world behind the challenge.
	get_viewport().set_input_as_handled()


## Place a bone directly over the plate. Used by the smoke test.
func bone_at_plate(golden: bool = false) -> void:
	var bone := _spawn_bone(tray_x, golden)
	bone["y"] = TRAY_Y
	var poly: Polygon2D = bone["node"]
	poly.position.y = TRAY_Y


## Place a bone past the plate so it counts as dropped. Used by the smoke test.
func bone_past_plate() -> void:
	var bone := _spawn_bone(tray_x + 120.0, false)
	bone["y"] = PLAY_HEIGHT + 8.0
	var poly: Polygon2D = bone["node"]
	poly.position.y = PLAY_HEIGHT + 8.0


func _width() -> float:
	var width := play_area.size.x
	return width if width > 50.0 else PLAY_WIDTH


func _move_tray(delta: float) -> void:
	var direction := 0.0
	if Input.is_action_pressed("left") or Input.is_action_pressed("ui_left"):
		direction -= 1.0
	if Input.is_action_pressed("right") or Input.is_action_pressed("ui_right"):
		direction += 1.0
	if direction == 0.0:
		return
	tray_x = clampf(
		tray_x + direction * tray_speed * delta,
		TRAY_HALF + 3.0,
		_width() - TRAY_HALF - 3.0,
	)
	_update_tray()


func _spawn_bone(x: float, golden: bool = false) -> Dictionary:
	var poly := Polygon2D.new()
	poly.polygon = _bone_points()
	poly.color = GOLD_COLOR if golden else BONE_COLOR
	poly.position = Vector2(x, -8.0)
	poly.rotation = _rng.randf_range(-0.4, 0.4)
	poly.scale = Vector2(1.25, 1.25) if golden else Vector2(1.0, 1.0)
	play_area.add_child(poly)

	var speed := _rng.randf_range(46.0, 60.0) + float(_spawned) * 1.4
	var bone: Dictionary = {
		"node": poly,
		"x": x,
		"y": -8.0,
		"speed": minf(speed, 110.0),
		"golden": golden,
	}
	bones.append(bone)
	return bone


func _tick_bones(delta: float) -> void:
	var remaining: Array = []
	for bone in bones:
		var poly: Polygon2D = bone["node"]
		if not is_instance_valid(poly):
			continue
		bone["y"] = float(bone["y"]) + float(bone["speed"]) * delta
		poly.position.y = float(bone["y"])
		var caught := (
			float(bone["y"]) >= TRAY_Y - 3.0
			and absf(float(bone["x"]) - tray_x) <= TRAY_HALF + 2.0
		)
		if caught:
			_collect(bone)
			continue
		if float(bone["y"]) > PLAY_HEIGHT + 6.0:
			_drop(bone)
			continue
		remaining.append(bone)
	bones = remaining


func _collect(bone: Dictionary) -> void:
	var poly: Polygon2D = bone["node"]
	if is_instance_valid(poly):
		poly.queue_free()
	var golden: bool = bone["golden"]
	catches += 2 if golden else 1
	set_progress(float(catches) / float(catches_needed) * 100.0)
	if catches >= catches_needed:
		status_label.text = "Every bone accounted for. Rattle takes a bow!"
		complete()
	elif golden:
		status_label.text = "Golden bone! Two at once — %d / %d" % [catches, catches_needed]
	else:
		status_label.text = "Nice catch — %d / %d" % [catches, catches_needed]


func _drop(_bone: Dictionary) -> void:
	var poly: Polygon2D = _bone["node"]
	if is_instance_valid(poly):
		poly.queue_free()
	drops += 1
	var left := max_drops - drops
	status_label.text = "Missed — %d more and the act ends" % left
	if drops >= max_drops:
		fail()


func _update_tray() -> void:
	if _tray == null:
		return
	_tray.position = Vector2(tray_x, TRAY_Y)
	if _tray_rim != null:
		_tray_rim.position = Vector2(tray_x, TRAY_Y + 1.0)


func _build_play_area() -> void:
	for child in play_area.get_children():
		child.queue_free()
	bones.clear()
	_tray = null
	_tray_rim = null

	var background := ColorRect.new()
	background.color = BACKGROUND
	background.size = Vector2(_width(), PLAY_HEIGHT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	play_area.add_child(background)

	# A couple of dim spotlights so the stage reads as a stage.
	for x in [70.0, _width() - 70.0]:
		var glow := Polygon2D.new()
		glow.polygon = PackedVector2Array([
			Vector2(x - 18.0, 0.0),
			Vector2(x + 18.0, 0.0),
			Vector2(x + 42.0, PLAY_HEIGHT),
			Vector2(x - 42.0, PLAY_HEIGHT),
		])
		glow.color = Color(0.22, 0.32, 0.34, 0.30)
		play_area.add_child(glow)

	_tray_rim = Polygon2D.new()
	_tray_rim.polygon = PackedVector2Array([
		Vector2(-TRAY_HALF - 4.0, 0.0),
		Vector2(TRAY_HALF + 4.0, 0.0),
		Vector2(TRAY_HALF, 5.0),
		Vector2(-TRAY_HALF, 5.0),
	])
	_tray_rim.color = PLATE_DARK
	play_area.add_child(_tray_rim)

	_tray = Polygon2D.new()
	_tray.polygon = PackedVector2Array([
		Vector2(-TRAY_HALF, 0.0),
		Vector2(TRAY_HALF, 0.0),
		Vector2(TRAY_HALF - 5.0, 5.0),
		Vector2(-TRAY_HALF + 5.0, 5.0),
	])
	_tray.color = PLATE_COLOR
	play_area.add_child(_tray)
	_update_tray()


func _bone_points() -> PackedVector2Array:
	# A little horizontal bone with knobbly ends.
	return PackedVector2Array([
		Vector2(-8.0, -2.0),
		Vector2(-6.0, -4.0),
		Vector2(-3.0, -2.0),
		Vector2(3.0, -2.0),
		Vector2(6.0, -4.0),
		Vector2(8.0, -2.0),
		Vector2(8.0, 2.0),
		Vector2(6.0, 4.0),
		Vector2(3.0, 2.0),
		Vector2(-3.0, 2.0),
		Vector2(-6.0, 4.0),
		Vector2(-8.0, 2.0),
	])
