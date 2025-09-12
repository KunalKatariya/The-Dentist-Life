class_name Player extends CharacterBody2D

var cardinal_direction : Vector2 = Vector2.RIGHT #by default dir
var direction : Vector2 = Vector2.ZERO
var state : String = "idle"

var move_speed : float = 100.0
@onready var animation_player : AnimationPlayer = $AnimationPlayer
@onready var sprite : Sprite2D = $Sprite2D

#Called when the node enters the scene tree for the first time
func _ready():
	UpdateAnimation()
	pass #Replace with func body

#Called every frame, delta is the elapsed time since the prev frame
func _process(delta):
	direction.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	direction.y = Input.get_action_strength("down") - Input.get_action_strength("up")
	direction = direction.normalized()
	
	velocity = direction * move_speed
	
	# Update facing direction only if there’s horizontal input
	if direction.x != 0:
		cardinal_direction = Vector2.RIGHT if direction.x > 0 else Vector2.LEFT
	
	if SetState():
		UpdateAnimation()
	
	pass

func _physics_process(delta: float) -> void:
	move_and_slide()

func SetDirection() -> bool:
	return true

func SetState() -> bool:
	var new_state : String = "idle" if direction == Vector2.ZERO else "walk"
	if new_state == state:
		return false
	state = new_state
	return true

func UpdateAnimation() -> void:
	animation_player.play(state + "_" + AnimDirection())
	pass

func AnimDirection() -> String:
	if cardinal_direction == Vector2.LEFT:
		return "left"
	elif cardinal_direction == Vector2.RIGHT:
		return "right"
	# Fallback so the function always returns something
	return "right"
	

	
