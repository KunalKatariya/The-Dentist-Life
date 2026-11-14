extends Node2D  # Or whatever your root node is

const PLAYER_INFO := preload("res://Scenes/NPC/npc_player.tres")
const SUMMON_SPEED := 320.0
const RETURN_SPEED := 260.0

@onready var transition = $Transition
@onready var anim_player = $Transition/AnimationPlayer
@onready var npc = $Npc
@onready var player = $Player
@onready var path_badminton = $route_to_badminton
@onready var path_surprise = $route_to_surprise
@onready var path_chai = $route_to_chai
var going_back = false
var next_action: String = ""
var _kunal_home: Vector2 = Vector2.ZERO
var _kunal_busy: bool = false
var _kunal_tween: Tween = null

func _ready():
	# Optional: Fade in when the scene starts
	transition.show()
	anim_player.play("Fade_In")

	# Remember where Kunal stands so he can go back after a summoned hint.
	_kunal_home = npc.global_position

	# Connect animation finished signal
	anim_player.animation_finished.connect(_on_animation_finished)

	# Dialog branch actions are routed globally; react to the hub ones here.
	if not ActionRouter.action_requested.is_connected(_on_action_requested):
		ActionRouter.action_requested.connect(_on_action_requested)


## H summons Kunal to the player. He walks over, gives the current progress
## hint, then wanders back to his spot. The normal E conversation still only
## works when the player is actually standing next to him.
func _unhandled_input(event: InputEvent) -> void:
	if going_back or _kunal_busy or DialogSystem.is_active:
		return
	if event.is_action_pressed("call_hint") and not event.is_echo():
		get_viewport().set_input_as_handled()
		_summon_kunal()


func _summon_kunal() -> void:
	if _kunal_busy:
		return
	_kunal_busy = true
	_set_kunal_interaction_enabled(false)
	player.set_input_enabled(false)

	# Stand beside the player instead of on top of them.
	var side := 30.0 if npc.global_position.x <= player.global_position.x else -30.0
	var target: Vector2 = player.global_position + Vector2(side, 0)
	if npc.global_position.distance_to(target) > 6.0:
		var tween := _walk_kunal(target, SUMMON_SPEED)
		await tween.finished
	npc.animation.play("idle")
	npc.sprite.flip_h = player.global_position.x < npc.global_position.x

	await _show_kunal_hint()

	# Hand control back before Kunal heads home, so the player is never stuck
	# watching him walk the whole way across the village.
	_set_kunal_interaction_enabled(true)
	player.set_input_enabled(true)
	_kunal_busy = false
	_send_kunal_home()


func _set_kunal_interaction_enabled(enabled: bool) -> void:
	var interaction := npc.get_node_or_null("DialogInteraction") as DialogInteraction
	if interaction == null:
		return
	interaction.enabled = enabled
	if not enabled:
		interaction.player_in_area = false
		interaction.animation_player.play("hide")
		return
	# Re-arm the prompt without making the player step away and back.
	var scene := get_tree().current_scene
	var player_node: Node = scene.find_child("Player", true, false) if scene != null else null
	if player_node is Player and interaction.overlaps_body(player_node):
		interaction._on_area_enter(player_node)


func _walk_kunal(target: Vector2, speed: float) -> Tween:
	if _kunal_tween != null and _kunal_tween.is_valid():
		_kunal_tween.kill()
	npc.animation.play("walk_right")
	npc.sprite.flip_h = target.x < npc.global_position.x
	_kunal_tween = create_tween()
	var duration := maxf(0.2, npc.global_position.distance_to(target) / speed)
	_kunal_tween.tween_property(npc, "global_position", target, duration)
	return _kunal_tween


func _send_kunal_home() -> void:
	if npc.global_position.distance_to(_kunal_home) <= 6.0:
		_finish_kunal_return(_kunal_tween)
		return
	var tween := _walk_kunal(_kunal_home, RETURN_SPEED)
	tween.finished.connect(_finish_kunal_return.bind(tween))


func _finish_kunal_return(tween: Tween) -> void:
	if tween != _kunal_tween:
		return
	npc.animation.play("idle")
	npc.sprite.flip_h = false
	_kunal_tween = null


func _show_kunal_hint() -> void:
	var items := _hint_dialog_items()
	DialogSystem.show_dialog(items)
	await DialogSystem.finished
	for line in items:
		if is_instance_valid(line):
			line.queue_free()


func _hint_dialog_items() -> Array[DialogItem]:
	var items: Array[DialogItem] = []

	var greeting := DialogText.new()
	greeting.text = "You called, babe? I came as fast as I could."
	greeting.npc_info = npc.npc_resource
	items.append(greeting)

	var lines: Array[String]
	if not GameState.quest_started():
		lines = [
			"Is Priya looking for me?",
			"She is. The dentist lady at the clinic. Go hear her out first, then I will have all the gossip for you.",
		]
	else:
		var hint := npc.get_node_or_null("DialogInteraction/DialogChoice/DialogBranch5") as KunalHint
		lines = hint.hint_lines() if hint != null else [
			"Any tips?",
			"Give me a minute, babe. I am still asking around.",
		]

	for i in lines.size():
		var line := DialogText.new()
		line.text = lines[i]
		line.npc_info = PLAYER_INFO if i == 0 else npc.npc_resource
		items.append(line)
	return items


func _on_action_requested(action_name: String) -> void:
	# Hub-specific dialog branch action. Handled when the dialog finishes.
	next_action = action_name


func _input(event):
	if event.is_action_pressed("esc") and !going_back:
		# ESC key pressed
		GameState.save_current_scene_state()
		going_back = true
		transition.show()
		anim_player.play("Fade_Out")

func _on_animation_finished(anim_name: String) -> void:
	if anim_name == "Fade_Out" and going_back:
		# Return to main menu after fade out
		SceneRouter.go("menu")

func _on_npc_dialog_finished(npc_ref: Node):
	var action := next_action
	next_action = ""
	print("[Playground] NPC dialog finished. next_action =", action)
	match action:
		"go_to_badminton":
			print("[Playground] Starting badminton route")
			await _npc_guided_walk(path_badminton, "res://Scenes/Badminton/badminton_game.tscn")
		"go_to_surprise":
			print("[Playground] Starting surprise route")
			await _npc_guided_walk(path_surprise, "res://Scenes/Surprise/Surprise.tscn")
		"go_to_chai":
			print("[Playground] Starting chai route")
			await _npc_guided_walk(path_chai, "res://Scenes/AIChat/AIChat.tscn")
		"go_to_exit":
			print("[Playground] Exiting chat")
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
	GameState.set_scene_position(current_scene_path, player.global_position)
	
	# --- END SAVE ---

	anim_player.play("Fade_Out")
	await anim_player.animation_finished
	SceneRouter.go_to_path(target_scene)

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
	SceneRouter.go_to_path(target_scene)


func _on_scene_trigger_body_entered(body: Node2D) -> void:
	pass # Replace with function body.
