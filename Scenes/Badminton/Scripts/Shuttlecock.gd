# res://Badminton/Scripts/Shuttlecock.gd
extends RigidBody2D
class_name Shuttlecock

@export var base_speed: float = 140.0

func _ready() -> void:
	add_to_group("shuttle")

func serve(direction: Vector2) -> void:
	# Normalize just in case, add a tiny angle so it's not perfectly straight
	var d := direction.normalized()
	var angle_jitter := randf_range(-0.12, 0.12)
	var v := d.rotated(angle_jitter) * base_speed
	linear_velocity = v
	angular_velocity = 2.0  # radians/sec, adjust for spin speed

func _physics_process(delta: float) -> void:
	if linear_velocity.length() > 0:
		linear_velocity = linear_velocity.normalized() * base_speed
