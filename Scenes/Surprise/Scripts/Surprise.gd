extends Node2D

@export var dialog_items: Array[DialogItem] = []
@export var audio_stream: AudioStream # New: For the audio
@export var full_light_scale: float = 20.0 # Adjust this scale for the final visible area size

@onready var light_2d: Light2D = $Light2D
@onready var canvas_modulate: CanvasModulate = $CanvasModulate
@onready var interaction_zone: Area2D = $InteractionZones
@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D
@onready var player: Node2D = $Player

# --- INITIAL SETUP ---
func _ready():
	canvas_modulate.color = Color.BLACK
	$BGSwitchTimer.connect("timeout", Callable(self, "_on_timer_timeout"))
	interaction_zone.connect("body_entered", Callable(self, "_on_interaction_zone_body_entered"))

	if dialog_items.size() > 0:
		DialogSystem.show_dialog(dialog_items)


func _on_interaction_zone_body_entered(body: Node2D):
	if body.name == "Player":
		interaction_zone.disconnect("body_entered", Callable(self, "_on_interaction_zone_body_entered"))
		reveal_scene()

func reveal_scene():
	# --- 1. Lock player movement ---
	if player.has_method("set_input_enabled"):
		player.set_input_enabled(false)
	print("Audio player:", audio_player)
	print("Audio stream:", audio_stream)
	# --- 2. Play audio ---
	if audio_stream:
		audio_player.stream = audio_stream
		audio_player.play()

	# --- 3. Animate reveal ---
	var tween = create_tween()
	tween.tween_property(light_2d, "scale", Vector2(full_light_scale, full_light_scale), 3.0)
	tween.tween_property(canvas_modulate, "color", Color.WHITE, 3.0)
	tween.tween_property(light_2d, "energy", 0.0, 3.0)


	# --- 4. Wait until both tween + audio finish, then unlock ---
	var total_time = max(audio_player.stream.get_length(), 3.0)
	tween.tween_callback(Callable(self, "_on_reveal_finished")).set_delay(total_time)


func _on_reveal_finished():
	if player.has_method("set_input_enabled"):
		player.set_input_enabled(true)

func _on_timer_timeout():
	$BG1.visible = !$BG1.visible
	$BG2.visible = !$BG2.visible
