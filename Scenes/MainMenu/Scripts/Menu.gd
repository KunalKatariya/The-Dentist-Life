extends Node2D

@onready var start_button = $Buttons_Manager/StartButton
@onready var exit_button = $Buttons_Manager/ExitButton
@onready var transition = $Transition
@onready var anim_player = $Transition/AnimationPlayer
@onready var music_player = $AudioStreamPlayer
@onready var mouse_click = $MouseClick


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
	if not start_button.pressed.is_connected(_on_start_button_pressed):
		start_button.pressed.connect(_on_start_button_pressed)
	if not exit_button.pressed.is_connected(_on_exit_button_pressed):
		exit_button.pressed.connect(_on_exit_button_pressed)

	# Connect animation_finished signal
	anim_player.animation_finished.connect(_on_animation_finished)

func _on_start_button_pressed() -> void:
	print("Start button pressed")
	mouse_click.play()
	button_type = "start"
	transition.show()
	anim_player.play("Fade_Out")

func _on_exit_button_pressed() -> void:
	mouse_click.play()
	anim_player.play("Fade_Out")
	await mouse_click.finished
	get_tree().quit()

func _on_animation_finished(anim_name: String) -> void:
	print("Animation finished:", anim_name)
	if anim_name == "Fade_Out":
		if button_type == "start":
			SceneRouter.go("hub")
		else:
			get_tree().quit()
