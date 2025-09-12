# res://Badminton/Scripts/Opponent.gd
extends CharacterBody2D

@export var speed: float = 220.0
@export var hit_range: float = 30.0
@export var hit_cooldown: float = 0.35
@export var hit_jitter: float = 0.12  # radians
@export var move_area: Rect2 = Rect2(Vector2(10, 10), Vector2(245, 280))
# Example: left half of 512x288 court. Adjust in Inspector if needed.

var _cooldown: float = 0.0

func _physics_process(delta: float) -> void:
	_cooldown = max(_cooldown - delta, 0.0)

	var shuttle: RigidBody2D = null
	var list: Array = get_tree().get_nodes_in_group("shuttle")
	if list.size() > 0:
		shuttle = list[0] as RigidBody2D

	if shuttle == null:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# --- Y MOVEMENT ONLY ---
	var dy: float = shuttle.global_position.y - global_position.y
	var vy: float = 0.0
	if abs(dy) > 2.0:
		vy = sign(dy) * speed
	velocity = Vector2(0, vy)

	# Clamp inside its allowed half
	var new_pos := global_position + velocity * delta
	new_pos.x = clampf(new_pos.x, move_area.position.x, move_area.position.x + move_area.size.x)
	new_pos.y = clampf(new_pos.y, move_area.position.y, move_area.position.y + move_area.size.y)
	global_position = new_pos

	# --- HIT shuttle back when close ---
	if _cooldown <= 0.0 and global_position.distance_to(shuttle.global_position) <= hit_range:
		var jitter := randf_range(-hit_jitter, hit_jitter)
		# Always hit to the RIGHT (towards player side)
		shuttle.linear_velocity = Vector2.RIGHT.rotated(jitter).normalized() * shuttle.linear_velocity.length()
		_cooldown = hit_cooldown
