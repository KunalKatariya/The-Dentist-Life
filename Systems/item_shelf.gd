class_name ItemShelf extends Area2D
## Wall display of the six pieces of clinic equipment.
##
## Missing equipment is shown as a faint silhouette. Recovered equipment lights
## up. Interacting with the shelf opens the detective notebook checklist.

const COLUMNS := 3
const SLOT_SPACING := Vector2(26, 22)
const FIRST_SLOT := Vector2(-26, -6)
const BOARD_RECT := Rect2(-45, -22, 90, 48)

var player_near: bool = false
var _icons: Array[Sprite2D] = []

@onready var prompt: Label = $Prompt
@onready var slots: Node2D = $Slots


func _ready() -> void:
	prompt.hide()
	_build_icons()
	GameState.item_recovered.connect(_on_item_recovered)
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_refresh()


func _build_icons() -> void:
	for i in ItemCatalog.ITEMS.size():
		var item: ItemResource = ItemCatalog.ITEMS[i]
		var icon := Sprite2D.new()
		icon.texture = item.icon
		icon.position = _slot_position(i)
		icon.scale = Vector2(1.25, 1.25)
		slots.add_child(icon)
		_icons.append(icon)


func _slot_position(index: int) -> Vector2:
	return FIRST_SLOT + Vector2(
		SLOT_SPACING.x * (index % COLUMNS),
		SLOT_SPACING.y * (index / COLUMNS)
	)


func _draw() -> void:
	draw_rect(BOARD_RECT, Color(0.98, 0.94, 0.84, 0.92))
	draw_rect(BOARD_RECT, Color(0.45, 0.37, 0.26, 1.0), false, 2.0)
	for i in ItemCatalog.ITEMS.size():
		var center := _slot_position(i)
		draw_rect(
			Rect2(center - Vector2(11, 11), Vector2(22, 22)),
			Color(0.66, 0.58, 0.45, 0.65), false, 1.0
		)


func _refresh() -> void:
	for i in _icons.size():
		var item: ItemResource = ItemCatalog.ITEMS[i]
		var have := GameState.has_item(item.id)
		_icons[i].modulate = Color(1, 1, 1, 1) if have else Color(0.18, 0.15, 0.12, 0.28)


func _on_item_recovered(_item_id: String) -> void:
	_refresh()


func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		player_near = true
		prompt.show()


func _on_body_exited(body: Node2D) -> void:
	if body is Player:
		player_near = false
		prompt.hide()


func _unhandled_input(event: InputEvent) -> void:
	if player_near and event.is_action_pressed("interact"):
		if get_tree().paused or DialogSystem.is_active:
			return
		get_viewport().set_input_as_handled()
		GameHUD.open_notebook()
