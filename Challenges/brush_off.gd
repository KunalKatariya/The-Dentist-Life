class_name BrushOff extends ChallengeBase
## Mash Space or E to scrub Blorb off the dental mirror.
##
## Brushing progress slowly decays so the player has to keep a steady rhythm.
## Missing the timer is harmless: retry, or skip after three attempts.

const BLORB_TEXTURE := preload("res://Assets_Imported/villains/blorb.png")

@export var brush_strength: float = 3.0
@export var brush_decay: float = 2.0

var _brush: float = 0.0
var _wiggle: float = 0.0
var _blorb: Sprite2D


func _on_attempt_started() -> void:
	_brush = 0.0
	_wiggle = 0.0
	set_progress(0.0)
	status_label.text = "Mash SPACE or E to brush!"
	if _blorb == null:
		_blorb = Sprite2D.new()
		_blorb.texture = BLORB_TEXTURE
		_blorb.position = Vector2(184, 30)
		play_area.add_child(_blorb)
	_blorb.position = Vector2(184, 30)
	_blorb.rotation = 0.0


func _on_tick(delta: float) -> void:
	_brush = maxf(0.0, _brush - brush_decay * delta)
	set_progress(_brush)
	_wiggle += delta
	if _blorb != null:
		var wobble := 0.6 + _brush * 0.03
		_blorb.position.y = 30.0 + sin(_wiggle * 9.0) * wobble
		_blorb.rotation = sin(_wiggle * 6.0) * 0.04
	status_label.text = "Brushing... %d%%" % int(_brush)
	if _brush >= 100.0:
		complete()


func _unhandled_input(event: InputEvent) -> void:
	if not running:
		return
	if not (event.is_action_pressed("hit") or event.is_action_pressed("interact")):
		return
	get_viewport().set_input_as_handled()
	_brush = minf(100.0, _brush + brush_strength)
	set_progress(_brush)
	status_label.text = "Brushing... %d%%" % int(_brush)
	if _blorb != null:
		_blorb.position.x = 184.0 + randf_range(-3.0, 3.0)
	if _brush >= 100.0:
		complete()
