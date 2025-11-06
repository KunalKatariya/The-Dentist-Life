extends Node2D  # Or whatever your root node is

@onready var transition = $Transition
@onready var anim_player = $Transition/AnimationPlayer
@onready var npc = $Npc
@onready var player = $Player
@onready var path_badminton = $route_to_badminton
@onready var path_surprise = $route_to_surprise
@onready var path_chai = $route_to_chai
var going_back = false
var next_action: String = ""

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

func _on_npc_dialog_finished(npc_ref: Node):
	print("[Playground] NPC dialog finished. next_action =", next_action)
	match next_action:
		"go_to_badminton":
			print("[Playground] Starting badminton route")
			await _npc_guided_walk(path_badminton, "res://Scenes/Badminton/badminton_game.tscn")
		"go_to_surprise":
			print("[Playground] Starting surprise route")
			await _npc_guided_walk(path_surprise, "res://Scenes/Surprise/Surprise.tscn")
		"go_to_chai":
			print("[Playground] Starting chai route")
			await _npc_guided_walk(path_chai, "res://Scenes/AIChat/AIChat.tscn")
		_:
			print("[Playground] No valid action set, doing nothing")
			
			
func _npc_guided_walk(path: Path2D, target_scene: String) -> void:
	get_tree().paused = false
	player.set_process(false)
	player.velocity = Vector2.ZERO

	var follower: PathFollow2D = path.get_node("PathFollow2D")
	# Snap the path follower to the NPC’s current location on the curve
	var curve := path.curve
	var nearest_offset := curve.get_closest_offset(path.to_local(npc.global_position))
	var total_length := curve.get_baked_length()
	var walk_speed := 150.0 # pixels per second (tune this)
	var duration := total_length / walk_speed
	follower.progress = nearest_offset
	
	var tween := create_tween()
	tween.tween_property(follower, "progress_ratio", 1.0, duration)
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.set_ease(Tween.EASE_IN)

	npc.animation.play("idle")
	player.animation_player.play("left")

	# 🚀 manual frame update loop
	while tween.is_running():
		var prev_pos = npc.global_position
		npc.global_position = follower.global_position
		player.global_position = npc.global_position - Vector2(32, 0)

		var dir = (npc.global_position - prev_pos).normalized()
		_update_walk_animation(dir)

		await get_tree().process_frame

	# ✅ When tween finishes
	npc.animation.play("idle")
	player.animation_player.play("idle")
	
	# --- NEW: SAVE FINAL POSITION BEFORE TRANSITION ---
	var current_scene_path = get_tree().current_scene.scene_file_path
	
	# 1. Save the player's final global position in the Playground scene
	GameManager.scene_positions[current_scene_path] = player.global_position
	
	# --- END SAVE ---

	anim_player.play("Fade_Out")
	await anim_player.animation_finished
	get_tree().change_scene_to_file(target_scene)

func _on_path_step(follower: PathFollow2D) -> void:
	# Move NPC
	var prev_pos = npc.global_position
	npc.global_position = follower.global_position

	# Move Player slightly behind NPC (adjust offset as you prefer)
	player.global_position = npc.global_position - Vector2(16, 0)

	# Determine direction to next point
	var dir = (npc.global_position - prev_pos).normalized()
	_update_walk_animation(dir)

func _update_walk_animation(dir: Vector2) -> void:
	# Choose animation direction based on movement vector
	if abs(dir.x) > abs(dir.y):
		if dir.x > 0:
			npc.sprite.flip_h = false
			npc.animation.play("walk_right")
			player.animation_player.play("walk_right")
		else:
			npc.sprite.flip_h = true
			npc.animation.play("walk_right")
			player.animation_player.play("walk_left")
	else:
		if dir.y > 0:
			npc.sprite.flip_h = false
			npc.animation.play("walk_right")
			player.animation_player.play("walk_right")
		else:
			npc.animation.play("walk_right")
			player.animation_player.play("walk_right")

func _on_path_finished(target_scene: String) -> void:
	npc.animation.play("idle")
	player.animation_player.play("idle_right")

	anim_player.play("Fade_Out")
	await anim_player.animation_finished
	get_tree().change_scene_to_file(target_scene)


func _on_scene_trigger_body_entered(body: Node2D) -> void:
	pass # Replace with function body.
