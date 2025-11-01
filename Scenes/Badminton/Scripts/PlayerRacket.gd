# res://Badminton/Scripts/PlayerRacket.gd
extends CharacterBody2D

@export var move_speed: float = 200.0
@export var move_area: Rect2 = Rect2(Vector2(256, 10), Vector2(245, 280))

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var footstep_audio: AudioStreamPlayer2D = $FootstepAudio


var is_walking := false


func _physics_process(delta: float) -> void:
	var dir := Vector2(
		Input.get_action_strength("right") - Input.get_action_strength("left"),
		Input.get_action_strength("down") - Input.get_action_strength("up")
	).normalized()

	var new_pos := global_position + dir * move_speed * delta
	new_pos.x = clampf(new_pos.x, move_area.position.x, move_area.position.x + move_area.size.x)
	new_pos.y = clampf(new_pos.y, move_area.position.y, move_area.position.y + move_area.size.y)
	global_position = new_pos

	_update_animation(dir)

func _update_animation(dir: Vector2) -> void:
	# Always face left in badminton scene
	var new_anim := ""
	if dir.length() > 0.1:
		new_anim = "walk_left"
	else:
		new_anim = "idle_left"

	if animation_player.current_animation != new_anim:
		animation_player.play(new_anim)

	# Optional: Footstep control
	if dir.length() > 0.1:
		if not is_walking:
			is_walking = true
			#footstep_audio.play()
	else:
		if is_walking:
			is_walking = false
			#footstep_audio.stop()
