# res://Badminton/Scripts/PlayerRacket.gd
extends CharacterBody2D

@export var move_speed: float = 300.0
# Define the rectangle you want the player to be confined in (set in Inspector)
@export var move_area: Rect2 = Rect2(Vector2(256, 10), Vector2(245, 280))
# ^ Example numbers assuming ~1280x720 canvas:
#   position=(x=700,y=220), size=(w=420,h=280)  → right half of court.

func _physics_process(delta: float) -> void:
	var dir := Vector2(
		Input.get_action_strength("right") - Input.get_action_strength("left"),
		Input.get_action_strength("down")  - Input.get_action_strength("up")
	).normalized()

	var new_pos := global_position + dir * move_speed * delta
	# Clamp to allowed rectangle
	new_pos.x = clampf(new_pos.x, move_area.position.x, move_area.position.x + move_area.size.x)
	new_pos.y = clampf(new_pos.y, move_area.position.y, move_area.position.y + move_area.size.y)
	global_position = new_pos
