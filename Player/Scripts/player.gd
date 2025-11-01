class_name Player extends CharacterBody2D


var cardinal_direction: Vector2 = Vector2.RIGHT # by default dir
var direction: Vector2 = Vector2.ZERO
var state: String = "idle"
var move_speed: float = 100.0
var walking: bool = false
var input_enabled: bool = true

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite: Sprite2D = $Sprite2D
@onready var footstep_audio: AudioStreamPlayer2D = $FootstepAudio


# Called when the node enters the scene tree for the first time
func _ready():
	call_deferred("_set_saved_position")
		
	UpdateAnimation()

func _set_saved_position():
	var current_scene_path = get_tree().current_scene.scene_file_path
	if GameManager.scene_positions.has(current_scene_path):
		var saved_position = GameManager.scene_positions[current_scene_path]
		global_position = saved_position

# Called every frame
func _process(delta):
	if not input_enabled:
		direction = Vector2.ZERO
		velocity = Vector2.ZERO
		if walking:
			walking = false
			_stop_footsteps()
		return
		
	direction.x = Input.get_action_strength("right") - Input.get_action_strength("left")
	direction.y = Input.get_action_strength("down") - Input.get_action_strength("up")
	direction = direction.normalized()

	velocity = direction * move_speed

	# Update facing direction only if there’s horizontal input
	if direction.x != 0:
		cardinal_direction = Vector2.RIGHT if direction.x > 0 else Vector2.LEFT

	if SetState():
		UpdateAnimation()

	# Footstep control
	if direction != Vector2.ZERO:
		if not walking:
			walking = true
			_start_footsteps()
	else:
		if walking:
			walking = false
			_stop_footsteps()

func _physics_process(delta: float) -> void:
	move_and_slide()

func SetDirection() -> bool:
	return true

func SetState() -> bool:
	var new_state: String = "idle" if direction == Vector2.ZERO else "walk"
	if new_state == state:
		return false
	state = new_state
	return true

func UpdateAnimation() -> void:
	animation_player.play(state + "_" + AnimDirection())

func AnimDirection() -> String:
	if cardinal_direction == Vector2.LEFT:
		return "left"
	elif cardinal_direction == Vector2.RIGHT:
		return "right"
	# Fallback so the function always returns something
	return "right"

# Footstep functions
func _start_footsteps():
	if not footstep_audio.playing:
		footstep_audio.play()

func _stop_footsteps():
	footstep_audio.stop()

func set_input_enabled(enabled: bool):
	input_enabled = enabled
	if not enabled:
		# Immediately set to idle and update animation
		direction = Vector2.ZERO
		state = "idle"
		UpdateAnimation()
		_stop_footsteps()
