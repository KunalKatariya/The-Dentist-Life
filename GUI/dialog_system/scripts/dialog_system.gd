@tool	
class_name DialogSystemNode 	extends CanvasLayer

var is_active : bool = false
signal finished
signal letter_added(letter : String)

var dialog_items : Array[DialogItem]
var dialog_item_index : int = 0
var text_in_progress : bool = false
var text_speed : float = 0.02
var text_length : int = 0
var plain_text : String

@onready var dialog_ui : Control = $DialogUI
@onready var content : RichTextLabel = $DialogUI/PanelContainer/RichTextLabel
@onready var name_label : Label = $DialogUI/NameLabel
@onready var portrait_sprite : DialogPortrait = $DialogUI/PortraitSprite
@onready var dialog_progress_indicator : PanelContainer = $DialogUI/DialogProgressIndicator
@onready var dialog_progress_indicator_label : Label = $DialogUI/DialogProgressIndicator/Label
@onready var timer : Timer = $DialogUI/Timer
@onready var audio_stream_player = $DialogUI/AudioStreamPlayer

func _ready() -> void:
	timer.timeout.connect(_on_timer_timeout)
	hide_dialog()
	pass

func _unhandled_input(event: InputEvent) -> void:
	if is_active == false:
		return
	if(
		event.is_action_pressed("ui_accept") or
		event.is_action_pressed("test")
	):
		if text_in_progress == true:
			content.visible_characters = text_length
			timer.stop()
			text_in_progress = false
			show_dialog_button_indicator(true)
			return
		if dialog_item_index < dialog_items.size()-1:
			dialog_item_index += 1
			start_dialog()
		else:
			hide_dialog()
	pass
	
	
func show_dialog(_items : Array[ DialogItem ]) -> void:
	is_active = true
	dialog_ui.visible = true
	dialog_ui.process_mode = Node.PROCESS_MODE_ALWAYS
	dialog_items = _items
	dialog_item_index = 0
	get_tree().paused = true
	await get_tree().process_frame
	start_dialog()
	pass

func hide_dialog() -> void:
	is_active = false
	dialog_ui.visible = false
	dialog_ui.process_mode = Node.PROCESS_MODE_DISABLED
	get_tree().paused = false
	finished.emit()
	dialog_item_index = 0  # Reset for next time
	pass

func start_dialog() -> void:
	show_dialog_button_indicator(false)
	var _d : DialogItem = dialog_items[ dialog_item_index ]
	
	set_dialog_data(_d)
	content.visible_characters = 0
	text_length = content.get_total_character_count()
	plain_text = content.get_parsed_text()
	text_in_progress = true
	start_timer()
	pass

func set_dialog_data( _d : DialogText ) -> void:
	if _d is DialogItem:
		content.text = _d.text
	name_label.text = _d.npc_info.npc_name
	portrait_sprite.texture = _d.npc_info.portrait
	portrait_sprite.audio_pitch_base = _d.npc_info.dialog_audio_pitch
	pass


## Set dialog choice UI based on parameters

func show_dialog_button_indicator(_is_visible : bool) -> void:
	dialog_progress_indicator.visible = _is_visible
	if dialog_item_index < dialog_items.size()-1:
		dialog_progress_indicator_label.text = "Next"
	else:
		dialog_progress_indicator_label.text = "End"
	pass


func start_timer() -> void:
	timer.wait_time = text_speed
	#Manipulate wait time later
	var _char = plain_text[content.visible_characters - 1]
	if '.!?:;'.contains(_char):
		timer.wait_time *= 4
	elif ', '.contains(_char):
		timer.wait_time *= 2	
	timer.start()
	pass
	
func _on_timer_timeout() -> void:
	content.visible_characters += 1
	if content.visible_characters <= text_length:
		letter_added.emit(plain_text[content.visible_characters - 1])
		start_timer()
	else:
		show_dialog_button_indicator(true)
		text_in_progress = false
	pass
