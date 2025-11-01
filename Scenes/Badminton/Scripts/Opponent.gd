extends CharacterBody2D

@export var speed: float = 220.0
@export var hit_range: float = 20.0
@export var hit_cooldown: float = 0.35
@export var hit_jitter: float = 0.12
@export var move_area: Rect2 = Rect2(Vector2(10, 10), Vector2(245, 280))

# 🎯 "Human-ness" parameters
@export var reaction_delay: float = 0.25  # wait time before reacting to a new rally
@export var base_miss_chance: float = 0.2 # base % chance to miss (0–1)
@export var speed_miss_scale: float = 0.25 # extra miss chance per 400px/s shuttle speed
@export var reach_error_margin: float = 5.0 # additional distance margin for delayed reaction

var _cooldown: float = 0.0
var _ready_to_react: bool = false

func _ready() -> void:
	# small initial delay
	_ready_to_react = false
	await get_tree().create_timer(reaction_delay).timeout
	_ready_to_react = true

func _physics_process(delta: float) -> void:
	if not _ready_to_react:
		return

	_cooldown = maxf(_cooldown - delta, 0.0)

	var list := get_tree().get_nodes_in_group("shuttle")
	if list.is_empty():
		velocity = Vector2.ZERO
		move_and_slide()
		return
	var shuttle := list[0] as RigidBody2D

	# --- Slightly delayed follow logic ---
	if randf() < 0.03:
		# simulate inconsistent tracking (3% frames skipped)
		return

	var dy: float = shuttle.global_position.y - global_position.y
	var vy: float = clampf(dy * 3.0, -speed, speed)
	velocity = Vector2(0.0, vy)
	move_and_slide()

	# Clamp inside allowed half
	global_position.x = clampf(global_position.x, move_area.position.x, move_area.position.x + move_area.size.x)
	global_position.y = clampf(global_position.y, move_area.position.y, move_area.position.y + move_area.size.y)

	# --- Try to hit ---
	if _cooldown <= 0.0:
		var dist := global_position.distance_to(shuttle.global_position)
		if dist <= hit_range + reach_error_margin:
			_try_hit(shuttle)

func _try_hit(shuttle: RigidBody2D) -> void:
	var miss_chance := base_miss_chance + (shuttle.linear_velocity.length() / 400.0) * speed_miss_scale
	if randf() < miss_chance:
		# 👎 Miss the shot
		_cooldown = hit_cooldown * 2.0
		return

	# ✅ Successful return
	var jitter := randf_range(-hit_jitter, hit_jitter)
	var new_dir := Vector2.RIGHT.rotated(jitter)
	shuttle.linear_velocity = new_dir * shuttle.linear_velocity.length()
	_cooldown = hit_cooldown

	# 🟢 Play hit sound
	if shuttle.has_node("HitSound"):
		var hit_sound := shuttle.get_node("HitSound") as AudioStreamPlayer2D
		hit_sound.stop()  # ensure we start clean
		hit_sound.global_position = global_position
		hit_sound.pitch_scale = randf_range(0.95, 1.05)
		hit_sound.play()
		hit_sound.seek(2)  # ⏩ skip the first 0.05s of silence

	# Optional: delay before reacting again (so it doesn't chain instantly)
	_ready_to_react = false
	await get_tree().create_timer(reaction_delay).timeout
	_ready_to_react = true
