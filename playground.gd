extends Node2D  # Or whatever your root node is

@onready var transition = $Transition
@onready var anim_player = $Transition/AnimationPlayer

var going_back = false

func _ready():
	# Optional: Fade in when the scene starts
	transition.show()
	anim_player.play("Fade_In")

	# Connect animation finished signal
	anim_player.animation_finished.connect(_on_animation_finished)

func _input(event):
	if event.is_action_pressed("esc") and !going_back:
		# ESC key pressed
		going_back = true
		transition.show()
		anim_player.play("Fade_Out")

func _on_animation_finished(anim_name: String) -> void:
	if anim_name == "Fade_Out" and going_back:
		# Return to main menu after fade out
		get_tree().change_scene_to_file("res://Scenes/MainMenu/main_menu.tscn")
