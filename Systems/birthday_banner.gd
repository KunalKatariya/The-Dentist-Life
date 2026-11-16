class_name BirthdayBanner extends Node2D
## The banner Kunal hangs for the reopening. It appears once every piece of
## clinic equipment is home, so the finale has something to point at.
##
## Drawn in code so the pixels stay crisp at 480x270: a red cloth with gold
## trim, a scalloped hem and a single line of Abaddon Bold.

const BOLD: FontFile = preload("res://GUI/fonts/Abaddon Bold.ttf")
const MESSAGE := "Happy Birthday Dr. Gunika!"

const CLOTH_WIDTH := 168.0
const CLOTH_HEIGHT := 18.0
const SCALLOP_DEPTH := 6.0
const SCALLOPS := 8

const CLOTH_COLOR := Color(0.73, 0.21, 0.19, 1.0)
const CLOTH_SHADE := Color(0.55, 0.14, 0.14, 1.0)
const TRIM_COLOR := Color(0.98, 0.79, 0.33, 1.0)
const ROPE_COLOR := Color(0.28, 0.19, 0.13, 1.0)
const TEXT_COLOR := Color(1.0, 0.95, 0.80, 1.0)

@onready var label: Label = $Label


func _ready() -> void:
	label.add_theme_font_override("font", BOLD)
	label.text = MESSAGE
	GameState.item_recovered.connect(_on_progress_changed)
	GameState.flag_changed.connect(_on_flag_changed)
	_refresh()


func _on_progress_changed(_item_id: String) -> void:
	_refresh()


func _on_flag_changed(flag: String, _value: Variant) -> void:
	if flag == "clinic_restored":
		_refresh()


func _refresh() -> void:
	var unlocked := GameState.recovered_count() >= ItemCatalog.TOTAL
	visible = unlocked or GameState.has_flag("clinic_restored")


func _draw() -> void:
	var half := CLOTH_WIDTH * 0.5
	var step := CLOTH_WIDTH / float(SCALLOPS)

	# Rope tails that tie the cloth to the wall.
	draw_line(Vector2(-half - 9.0, 2.0), Vector2(-half, 2.0), ROPE_COLOR, 1.0)
	draw_line(Vector2(half, 2.0), Vector2(half + 9.0, 2.0), ROPE_COLOR, 1.0)
	draw_rect(Rect2(-half - 10.0, 1.0, 2.0, 2.0), TRIM_COLOR)
	draw_rect(Rect2(half + 8.0, 1.0, 2.0, 2.0), TRIM_COLOR)

	# Scalloped hem, drawn first so the cloth sits on top of it.
	for i in SCALLOPS:
		var x := -half + step * float(i)
		draw_colored_polygon(PackedVector2Array([
			Vector2(x, CLOTH_HEIGHT - 0.5),
			Vector2(x + step * 0.5, CLOTH_HEIGHT + SCALLOP_DEPTH),
			Vector2(x + step, CLOTH_HEIGHT - 0.5),
		]), CLOTH_COLOR)

	draw_rect(Rect2(-half, 0.0, CLOTH_WIDTH, CLOTH_HEIGHT), CLOTH_COLOR)
	# Bottom shade makes the folds read at this size.
	draw_rect(Rect2(-half, CLOTH_HEIGHT - 3.0, CLOTH_WIDTH, 3.0), CLOTH_SHADE)
	# Gold trim along the top and both sides.
	draw_rect(Rect2(-half, 0.0, CLOTH_WIDTH, 2.0), TRIM_COLOR)
	draw_rect(Rect2(-half, 0.0, 1.0, CLOTH_HEIGHT), TRIM_COLOR)
	draw_rect(Rect2(half - 1.0, 0.0, 1.0, CLOTH_HEIGHT), TRIM_COLOR)
	# And a thin gold edge on each scallop.
	for i in SCALLOPS:
		var x := -half + step * float(i)
		draw_line(
			Vector2(x, CLOTH_HEIGHT),
			Vector2(x + step * 0.5, CLOTH_HEIGHT + SCALLOP_DEPTH),
			Color(TRIM_COLOR, 0.55),
			1.0
		)
		draw_line(
			Vector2(x + step * 0.5, CLOTH_HEIGHT + SCALLOP_DEPTH),
			Vector2(x + step, CLOTH_HEIGHT),
			Color(TRIM_COLOR, 0.55),
			1.0
		)
