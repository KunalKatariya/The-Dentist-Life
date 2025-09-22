extends CharacterBody2D

func _ready():
	# Play idle animation as soon as NPC is ready
	$AnimatedSprite2D.play("idle")
