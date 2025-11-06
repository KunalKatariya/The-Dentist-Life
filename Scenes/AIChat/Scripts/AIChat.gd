extends Control

const CHAT_API_URL = "https://npc-backend-ai.onrender.com/chat"
const API_HEADERS = ["Content-Type: application/json"]
# Array to store history for full context (Memory)
var conversation_history: Array = []

@onready var message_display: RichTextLabel = $PanelContainer/VBoxContainer/RichTextLabel
@onready var message_input: TextEdit = $PanelContainer/VBoxContainer/TextEdit
@onready var http_request: HTTPRequest = $ChatRequest
@onready var npc_portrait: Sprite2D = $"NPCPortrait"
@onready var player_portrait: Sprite2D = $"PlayerPortrait"
@onready var exit_button: TextureButton = $TextureButton
@onready var npc_message_audio: AudioStreamPlayer = $NPCMessage
@onready var player_message_audio: AudioStreamPlayer = $PlayerMessage
@onready var bg_music: AudioStreamPlayer = $BGMusic

func _ready():
	print("Chat system ready")
	conversation_history.clear()
	bg_music.play()
	http_request.request_completed.connect(_on_http_request_completed)
	_display_message("> Hello girlf!", true)
	message_display.scale = Vector2(0.5, 0.5)
	exit_button.pressed.connect(_on_exit_button_pressed)
	message_input.grab_focus()
	message_input.gui_input.connect(_on_message_input_gui)

func _on_exit_button_pressed():
	# Stop the portrait animation (optional, but good practice)
	if is_instance_valid(npc_portrait):
		npc_portrait.stop_speaking()
	
		print("[SCENE] Exiting chat scene and returning to main scene...")
	
	# IMPORTANT: Change "res://main_scene.tscn" to the actual path of your main scene file!
	get_tree().change_scene_to_file("res://playground.tscn")

func _on_message_input_gui(event: InputEvent):
	player_portrait.start_speaking()
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ENTER and not event.shift_pressed:
			var user_message = message_input.text.strip_edges()
			if user_message != "":
				print("[INPUT] Sending message: ", user_message)
				_send_message(user_message)
				message_input.text = ""
				get_viewport().set_input_as_handled()

func _send_message(message: String):
	print("[SEND] Preparing HTTP request...")
	player_message_audio.play()
	_display_message("> " + message, false)
	message_input.editable = false
	
	npc_portrait.start_speaking()
	
	conversation_history.append({"role": "user", "content": message})

	var payload = {"messages": conversation_history}
	var body = JSON.stringify(payload)
	print("[SEND] JSON payload: ", body)
	print("[SEND] URL: ", CHAT_API_URL)
	print("[SEND] Headers: ", API_HEADERS)

	var error = http_request.request(CHAT_API_URL, API_HEADERS, HTTPClient.METHOD_POST, body)
	if error != OK:
		print("[ERROR] HTTP request failed to start. Error code: ", error)
		_display_message("AI: [Error: Failed to send request]", true)
		message_input.editable = true
		message_input.grab_focus()
	else:
		print("[SEND] HTTP request sent successfully, waiting for response...")

func _on_http_request_completed(result, response_code, headers, body):
	print("[RESPONSE] Request completed. Result code: ", result, ", HTTP code: ", response_code)
	npc_message_audio.play()
	message_input.editable = true
	message_input.grab_focus()

	if result != HTTPRequest.RESULT_SUCCESS:
		print("[ERROR] Network request failed with code: ", result)
		_handle_fatal_error()
		return

	var response_text = body.get_string_from_utf8()
	print("[RESPONSE] Raw response body: ", response_text)

	if response_code != 200:
		print("[ERROR] Server returned HTTP code ", response_code)
		_handle_fatal_error()
		return

	var json = JSON.new()
	var parse_result = json.parse(response_text)
	if parse_result != OK:
		print("[ERROR] Failed to parse JSON response. Code: ", parse_result)
		_handle_fatal_error()
		return

	var response_data = json.get_data()
	var ai_response_text = "[Error: Unexpected API response format or missing response key]"
	if response_data.has("reply"):
		ai_response_text = response_data.reply
	elif response_data.has("response"):
		ai_response_text = response_data.response

	if ai_response_text == "API_ERROR":
		print("[ERROR] Python script explicitly returned API_ERROR.")
		_handle_fatal_error() # This will perform the necessary history cleanup (pop_back)
		return
	conversation_history.append({"role": "model", "content": ai_response_text})
	print("[RESPONSE] Parsed AI response: ", ai_response_text)
	_display_message("> " + ai_response_text, true)

func _display_message(text: String, is_ai: bool):
	var color_tag: String
	var align_tag: String
	var formatted_text: String
	
	if is_ai:
		# AI: Greenish color, Left aligned
		color_tag = "[color=#A0FFFF]"
		align_tag = "[left]"
	else:
		# Player: Blueish color, Right aligned
		color_tag = "[color=#FFFF5C]"
		align_tag = "[right]"

	# Wrap the text in alignment and color tags, and add extra vertical spacing
	formatted_text = align_tag + color_tag + text + "[/color]"  + "\n"
	
	message_display.append_text(formatted_text)
	
	# Scroll to the bottom
	message_display.call_deferred("scroll_to_line", message_display.get_line_count())


func _handle_fatal_error():
	# Displays the required polite error message
	if not conversation_history.is_empty():
		conversation_history.pop_back()
	_display_message("> I'm sorry babe, I can't talk right now. I have a meeting :( TTYL", true)
