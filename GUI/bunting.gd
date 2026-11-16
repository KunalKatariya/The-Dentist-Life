extends Control
## Code-drawn bunting for the reopening card. Two sagging strings of little
## triangular flags, gently swaying, so the celebration fills the screen
## instead of sitting in a single panel.

const COLORS := [
	Color("#E85D5D"),
	Color("#F0B43C"),
	Color("#4FAF7A"),
	Color("#4A90C2"),
	Color("#D96BA0"),
	Color("#F2E3B3"),
]

@export var rows: int = 2
@export var flag_width: float = 10.0
@export var flag_height: float = 12.0
@export var spacing: float = 16.0

var _time: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var width := size.x
	if width <= 0.0:
		return
	for row in rows:
		var base_y := 7.0 + row * 22.0
		var sag := 5.0 + row * 2.0
		var x := -8.0 + row * 5.0
		var index := row * 3
		while x < width + 8.0:
			var t := (x + 8.0) / (width + 16.0)
			var y := base_y + sin(t * PI) * sag
			var sway := sin(_time * 1.6 + x * 0.12 + row) * 1.2
			var color: Color = COLORS[index % COLORS.size()]
			var points := PackedVector2Array([
				Vector2(x, y),
				Vector2(x + flag_width, y),
				Vector2(x + flag_width * 0.5, y + flag_height + sway),
			])
			draw_colored_polygon(points, color)
			# A warm highlight keeps the flags from reading as flat blocks.
			draw_line(
				Vector2(x, y),
				Vector2(x + flag_width, y),
				Color(1.0, 0.97, 0.86, 0.7),
				1.0,
			)
			index += 1
			x += spacing
		# The string above the flags.
		var steps := 10
		for i in steps:
			var x0 := (width + 16.0) * (float(i) / steps) - 8.0
			var x1 := (width + 16.0) * (float(i + 1) / steps) - 8.0
			var y0 := base_y + sin(((x0 + 8.0) / (width + 16.0)) * PI) * sag
			var y1 := base_y + sin(((x1 + 8.0) / (width + 16.0)) * PI) * sag
			draw_line(Vector2(x0, y0), Vector2(x1, y1), Color(0.32, 0.22, 0.18, 1.0), 1.0)
