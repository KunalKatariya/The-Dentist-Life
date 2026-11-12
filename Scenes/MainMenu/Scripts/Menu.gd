extends Node2D

@onready var start_button = $Buttons_Manager/StartButton
@onready var continue_button = $Buttons_Manager/ContinueButton
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
	if not continue_button.pressed.is_connected(_on_continue_button_pressed):
		continue_button.pressed.connect(_on_continue_button_pressed)
	if not exit_button.pressed.is_connected(_on_exit_button_pressed):
		exit_button.pressed.connect(_on_exit_button_pressed)
	_update_continue_button()

	# Connect animation_finished signal
	anim_player.animation_finished.connect(_on_animation_finished)


## Continue is only offered when there is a save to resume.
func _update_continue_button() -> void:
	var available := GameState.has_save()
	continue_button.disabled = not available
	continue_button.modulate = Color.WHITE if available else Color(1, 1, 1, 0.45)


func _on_start_button_pressed() -> void:
	if button_type != null:
		return
	print("Start button pressed")
	mouse_click.play()
	button_type = "start"
	transition.show()
	anim_player.play("Fade_Out")


func _on_continue_button_pressed() -> void:
	if button_type != null or not GameState.has_save():
		return
	print("Continue button pressed")
	mouse_click.play()
	button_type = "continue"
	transition.show()
	anim_player.play("Fade_Out")


func _on_exit_button_pressed() -> void:
	if button_type != null:
		return
	button_type = "exit"
	mouse_click.play()
	transition.show()
	anim_player.play("Fade_Out")


func _on_animation_finished(anim_name: String) -> void:
	print("Animation finished:", anim_name)
	if anim_name != "Fade_Out":
		return
	match button_type:
		"start":
			_start_new_game()
		"continue":
			_continue_game()
		"exit":
			get_tree().quit()


func _start_new_game() -> void:
	GameState.new_game()
	SceneRouter.clear_spawn()
	SceneRouter.go("hub")


func _continue_game() -> void:
	# Reload from disk so Continue always reflects the last saved state.
	if not GameState.load_game():
		_start_new_game()
		return
	SceneRouter.clear_spawn()
	var target := GameState.get_last_scene()
	if target.is_empty():
		SceneRouter.go("hub")
	else:
		SceneRouter.go_to_path(target)
