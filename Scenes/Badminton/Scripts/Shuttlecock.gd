extends RigidBody2D
class_name Shuttlecock

@export var base_speed: float = 150.0
@onready var hit_sound_player: AudioStreamPlayer2D = $HitSoundPlayer

func _ready() -> void:
	add_to_group("shuttle")
	contact_monitor = true
	max_contacts_reported = 5

func serve(direction: Vector2) -> void:
	var d := direction.normalized()
	var angle_jitter := randf_range(-0.12, 0.12)
	var v := d.rotated(angle_jitter) * base_speed
	linear_velocity = v
	angular_velocity = 2.0

func _physics_process(delta: float) -> void:
	if linear_velocity.length() > 0:
		linear_velocity = linear_velocity.normalized() * base_speed
