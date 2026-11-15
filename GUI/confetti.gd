class_name Confetti extends Control
## Code-drawn pixel confetti for the reopening card. No new art files: each
## piece is a tiny rectangle that drifts down the screen.

const COLORS := [
	Color("#E85D5D"),
	Color("#F0B43C"),
	Color("#4FAF7A"),
	Color("#4A90C2"),
	Color("#D96BA0"),
	Color("#F2E3B3"),
]

@export var piece_count: int = 70

var _pieces: Array[Dictionary] = []
var _time: float = 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rng.randomize()
	_reset_pieces()
	set_process(false)


## Start or restart the shower. Called when the reopening card opens.
func start() -> void:
	_reset_pieces()
	set_process(true)


func stop() -> void:
	set_process(false)


func _reset_pieces() -> void:
	_pieces.clear()
	var view := get_viewport_rect().size
	for i in piece_count:
		_pieces.append(_new_piece(view, true))
	queue_redraw()


func _new_piece(view: Vector2, allow_above: bool) -> Dictionary:
	return {
		"pos": Vector2(
			_rng.randf_range(0.0, view.x),
			_rng.randf_range(-view.y, 0.0) if allow_above else -4.0
		),
		"speed": _rng.randf_range(18.0, 52.0),
		"sway": _rng.randf_range(3.0, 11.0),
		"phase": _rng.randf_range(0.0, TAU),
		"size": Vector2(_rng.randi_range(1, 2), _rng.randi_range(2, 4)),
		"color": COLORS[_rng.randi_range(0, COLORS.size() - 1)],
	}


func _process(delta: float) -> void:
	_time += delta
	var view := get_viewport_rect().size
	for piece in _pieces:
		piece["pos"] = piece["pos"] + Vector2(
			sin(_time * 1.7 + piece["phase"]) * piece["sway"] * delta,
			piece["speed"] * delta
		)
		if piece["pos"].y > view.y + 4.0:
			var reset := _new_piece(view, false)
			piece["pos"] = Vector2(_rng.randf_range(0.0, view.x), -4.0)
			piece["speed"] = reset["speed"]
			piece["sway"] = reset["sway"]
			piece["phase"] = reset["phase"]
			piece["color"] = reset["color"]
	queue_redraw()


func _draw() -> void:
	for piece in _pieces:
		draw_rect(Rect2(piece["pos"].floor(), piece["size"]), piece["color"])
