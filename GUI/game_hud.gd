extends CanvasLayer
## Global quest HUD: equipment counter, notebook overlay and small toasts.
## Only visible in the hub and the clinic so the gift scenes stay untouched.

const HUD_SCENES := {
	"res://playground.tscn": true,
	"res://Scenes/Clinic/Clinic.tscn": true,
}

@onready var root: Control = $Root
@onready var counter_label: Label = $Root/CounterPanel/Counter
@onready var hint_label: Label = $Root/Hint
@onready var toast_panel: PanelContainer = $Root/ToastPanel
@onready var toast_label: Label = $Root/ToastPanel/Toast
@onready var notebook: Control = $Root/Notebook
@onready var quest_label: Label = $Root/Notebook/Panel/Margin/VBox/Quest
@onready var progress_label: Label = $Root/Notebook/Panel/Margin/VBox/Progress
@onready var items_box: VBoxContainer = $Root/Notebook/Panel/Margin/VBox/Items
@onready var close_button: Button = $Root/Notebook/Panel/Margin/VBox/Close

var _notebook_open: bool = false
var _rows: Array = []
var _toast_timer: Timer
var _player: Node = null


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	toast_panel.hide()
	notebook.hide()
	_build_rows()
	GameState.item_recovered.connect(_on_item_recovered)
	GameState.flag_changed.connect(_on_flag_changed)
	GameState.quest_stage_changed.connect(_on_quest_stage_changed)
	close_button.pressed.connect(close_notebook)
	_refresh()


func _process(_delta: float) -> void:
	var path := ""
	if get_tree().current_scene != null:
		path = get_tree().current_scene.scene_file_path
	var show_hud := HUD_SCENES.has(path)
	# Do not spoil the robbery before Priya has explained it.
	if show_hud and not GameState.has_flag("got_notebook") and GameState.get_quest_stage("restore_clinic") <= 0:
		show_hud = false
	root.visible = show_hud
	if not root.visible and _notebook_open:
		close_notebook()


func _unhandled_input(event: InputEvent) -> void:
	if not root.visible:
		return
	if event.is_action_pressed("notebook"):
		if _notebook_open:
			close_notebook()
		elif not DialogSystem.is_active and not get_tree().paused:
			open_notebook()
		get_viewport().set_input_as_handled()
	elif _notebook_open and event.is_action_pressed("ui_cancel"):
		close_notebook()
		get_viewport().set_input_as_handled()


func open_notebook() -> void:
	if not GameState.has_flag("got_notebook"):
		toast("Priya hasn't given you a notebook yet.")
		return
	_notebook_open = true
	_refresh()
	notebook.show()
	_set_player_input(false)
	get_tree().paused = true
	close_button.grab_focus()


func close_notebook() -> void:
	if not _notebook_open:
		return
	_notebook_open = false
	notebook.hide()
	get_tree().paused = false
	_set_player_input(true)


func _set_player_input(enabled: bool) -> void:
	if _player == null or not is_instance_valid(_player):
		var scene := get_tree().current_scene
		_player = scene.find_child("Player", true, false) if scene != null else null
	if _player != null and _player.has_method("set_input_enabled"):
		_player.set_input_enabled(enabled)


func toast(message: String) -> void:
	toast_label.text = message
	toast_panel.show()
	if _toast_timer != null and is_instance_valid(_toast_timer):
		_toast_timer.stop()
		_toast_timer.queue_free()
	_toast_timer = Timer.new()
	_toast_timer.wait_time = 2.8
	_toast_timer.one_shot = true
	_toast_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_toast_timer)
	_toast_timer.timeout.connect(_hide_toast)
	_toast_timer.start()


func _hide_toast() -> void:
	toast_panel.hide()
	if _toast_timer != null:
		_toast_timer.queue_free()
		_toast_timer = null


func _build_rows() -> void:
	for item in ItemCatalog.ITEMS:
		var typed_item: ItemResource = item
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 6)
		var mark := Label.new()
		mark.custom_minimum_size = Vector2(22, 0)
		mark.add_theme_font_size_override("font_size", 9)
		var name_label := Label.new()
		name_label.add_theme_font_size_override("font_size", 9)
		name_label.text = typed_item.display_name
		row.add_child(mark)
		row.add_child(name_label)
		items_box.add_child(row)
		_rows.append({"mark": mark, "name": name_label})


func _refresh() -> void:
	var count := GameState.recovered_count()
	counter_label.text = "EQUIPMENT  %d / %d" % [count, ItemCatalog.TOTAL]
	hint_label.visible = GameState.has_flag("got_notebook")
	progress_label.text = "Equipment recovered:  %d / %d" % [count, ItemCatalog.TOTAL]
	quest_label.text = _quest_text()
	for i in ItemCatalog.ITEMS.size():
		var item: ItemResource = ItemCatalog.ITEMS[i]
		var row: Dictionary = _rows[i]
		var have := GameState.has_item(item.id)
		var mark := row["mark"] as Label
		var name_label := row["name"] as Label
		mark.text = "[x]" if have else "[ ]"
		mark.add_theme_color_override(
			"font_color",
			Color("#1E7A44") if have else Color("#8A7862")
		)
		name_label.add_theme_color_override(
			"font_color",
			Color("#33502F") if have else Color("#7C6B57")
		)


func _quest_text() -> String:
	var stage := GameState.get_quest_stage("restore_clinic")
	if stage >= 5:
		return "The clinic is open. Take a breath, Doctor."
	if stage >= 4:
		return "All equipment recovered. Return to the clinic for reopening day."
	if stage >= 3:
		return "Recover the remaining equipment. Kunal in the village may have hints."
	if stage >= 2:
		return "The mirror set is still in the waiting room. Something green is sleeping on it."
	if stage >= 1:
		return "Recover the six pieces of stolen clinic equipment."
	return "Find out what happened at the clinic."


func _on_item_recovered(item_id: StringName) -> void:
	_refresh()
	var item: ItemResource = ItemCatalog.get_item(item_id)
	toast("%s recovered!" % (item.display_name if item != null else String(item_id)))


func _on_flag_changed(flag: String, value: Variant) -> void:
	if flag == "got_notebook" and value == true:
		toast("Detective Notebook added. Press N to open it.")
	_refresh()


func _on_quest_stage_changed(_quest_id: String, _stage: int) -> void:
	_refresh()
