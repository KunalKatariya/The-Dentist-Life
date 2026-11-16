class_name Confetti extends Control
## Code-drawn pixel confetti for the reopening card. No new art files: each
## piece is a tiny rectangle, a streamer or a little star that drifts down the
## screen. The shower is deliberately busy so reopening day feels like a party.

const COLORS := [
	Color("#E85D5D"),
	Color("#F0B43C"),
	Color("#4FAF7A"),
	Color("#4A90C2"),
	Color("#D96BA0"),
	Color("#F2E3B3"),
	Color("#F7F1DC"),
]

@export var piece_count: int = 150

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
	var kind := "rect"
	var roll := _rng.randf()
	if roll > 0.82:
		kind = "star"
	elif roll > 0.58:
		kind = "streamer"
	var piece_size := Vector2(
		_rng.randi_range(1, 2),
		_rng.randi_range(2, 4),
	)
	if kind == "streamer":
		piece_size = Vector2(1, _rng.randi_range(5, 10))
	return {
		"pos": Vector2(
			_rng.randf_range(0.0, view.x),
			_rng.randf_range(-view.y, 0.0) if allow_above else -4.0,
		),
		"speed": _rng.randf_range(18.0, 58.0),
		"sway": _rng.randf_range(3.0, 13.0),
		"phase": _rng.randf_range(0.0, TAU),
		"size": piece_size,
		"kind": kind,
		"color": COLORS[_rng.randi_range(0, COLORS.size() - 1)],
	}


func _process(delta: float) -> void:
	_time += delta
	var view := get_viewport_rect().size
	for piece in _pieces:
		piece["pos"] = piece["pos"] + Vector2(
			sin(_time * 1.7 + piece["phase"]) * piece["sway"] * delta,
			piece["speed"] * delta,
		)
		if piece["pos"].y > view.y + 8.0:
			var reset := _new_piece(view, false)
			piece["pos"] = Vector2(_rng.randf_range(0.0, view.x), -8.0)
			piece["speed"] = reset["speed"]
			piece["sway"] = reset["sway"]
			piece["phase"] = reset["phase"]
			piece["color"] = reset["color"]
			piece["kind"] = reset["kind"]
			piece["size"] = reset["size"]
	queue_redraw()


func _draw() -> void:
	for piece in _pieces:
		var pos: Vector2 = (piece["pos"] as Vector2).floor()
		var cell: Vector2 = piece["size"]
		var color: Color = piece["color"]
		match piece["kind"]:
			"streamer":
				# A tiny wave makes the ribbon look like it is fluttering.
				var bend := sin(_time * 3.0 + piece["phase"]) * 1.5
				draw_rect(Rect2(pos, cell), color)
				draw_rect(Rect2(pos + Vector2(bend, cell.y), Vector2(1, 1)), color)
			"star":
				draw_rect(Rect2(pos + Vector2(1, 0), Vector2(1, 3)), color)
				draw_rect(Rect2(pos + Vector2(0, 1), Vector2(3, 1)), color)
			_:
				draw_rect(Rect2(pos, cell), color)
