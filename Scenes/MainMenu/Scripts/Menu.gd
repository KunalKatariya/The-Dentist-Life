extends Node2D

@onready var start_button = $Buttons_Manager/StartButton
@onready var exit_button = $Buttons_Manager/ExitButton
@onready var transition = $Transition
@onready var anim_player = $Transition/AnimationPlayer
@onready var music_player = $AudioStreamPlayer


var button_type = null

func _ready():
	$Transition.show()
	$Transition/AnimationPlayer.play("Fade_In")
	$AnimatedSprite2D.play("main_anime")
	var stream = music_player.stream
	if stream is AudioStreamOggVorbis:
		stream.loop = true
		print("Loop enabled")
	else:
		print("Stream is not OGGVorbis:", stream)

	music_player.play()
	start_button.pressed.connect(_on_start_button_pressed)
	exit_button.pressed.connect(_on_exit_button_pressed)

	# Connect animation_finished signal
	anim_player.animation_finished.connect(_on_animation_finished)

func _on_start_button_pressed() -> void:
	print("Start button pressed")
	button_type = "start"
	transition.show()
	anim_player.play("Fade_Out")

func _on_exit_button_pressed() -> void:
	get_tree().quit()

func _on_animation_finished(anim_name: String) -> void:
	print("Animation finished:", anim_name)
	if anim_name == "Fade_Out":
		if button_type == "start":
			get_tree().change_scene_to_file("res://playground.tscn")
		else:
			get_tree().quit()
