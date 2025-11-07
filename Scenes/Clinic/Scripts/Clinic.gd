extends Node

@onready var transition = $Transition
@onready var anim_player = $Transition/AnimationPlayer

func _ready():
	# Optional: Fade in when the scene starts
	transition.show()
	anim_player.play("Fade_In")
