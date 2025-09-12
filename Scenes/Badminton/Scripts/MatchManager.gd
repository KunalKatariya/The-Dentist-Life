extends Node2D

const WIN_SCORE: int = 5

var player_score: int = 0
var opponent_score: int = 0
var serving_player: StringName = "player"
var point_locked: bool = false
var game_over: bool = false

@onready var score_label: Label = $CanvasLayer/ScoreLabel
@onready var message_label: Label = $CanvasLayer/MessageLabel
@onready var back_button: Button = $CanvasLayer/BackButton

# GameOver UI
@onready var game_over_menu: Control = $CanvasLayer/GameOverMenu
@onready var game_over_label: Label = $CanvasLayer/GameOverMenu/VBoxContainer/GameOverLabel
@onready var restart_button: Button = $CanvasLayer/GameOverMenu/VBoxContainer/RestartButton
@onready var back_button_menu: Button = $CanvasLayer/GameOverMenu/VBoxContainer/BackButtonMenu

@onready var player: Node2D = $Player
@onready var opponent: Node2D = $Opponent
@onready var shuttle: RigidBody2D = $Shuttlecock

@onready var zone_left: Area2D = $Court/ScoreZones/ZoneLeft
@onready var zone_right: Area2D = $Court/ScoreZones/ZoneRight

@onready var spawn_player: Marker2D = $Spawns/PlayerSpawn
@onready var spawn_opponent: Marker2D = $Spawns/OpponentSpawn
@onready var spawn_ball: Marker2D = $Spawns/BallSpawn

func _ready() -> void:
	zone_left.body_entered.connect(_on_zone_left_body_entered)
	zone_right.body_entered.connect(_on_zone_right_body_entered)

	back_button.pressed.connect(_on_back_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	back_button_menu.pressed.connect(_on_back_pressed)

	message_label.text = ""
	game_over_menu.hide()

	shuttle.add_to_group("shuttle")
	_reset_rally()

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://playground.tscn")

func _on_restart_pressed() -> void:
	player_score = 0
	opponent_score = 0
	serving_player = "player"
	game_over = false
	point_locked = false
	game_over_menu.hide()
	message_label.text = ""
	shuttle.sleeping = false
	_update_score()
	_reset_rally()

func _on_zone_left_body_entered(body: Node) -> void:
	if body.is_in_group("shuttle"):
		_freeze_shuttle()
		_point_scored(true)

func _on_zone_right_body_entered(body: Node) -> void:
	if body.is_in_group("shuttle"):
		_freeze_shuttle()
		_point_scored(false)


func _point_scored(by_player: bool) -> void:
	if point_locked or game_over:
		return
	point_locked = true

	if by_player:
		player_score += 1
		serving_player = "opponent"
	else:
		opponent_score += 1
		serving_player = "player"

	_update_score()

	if player_score >= WIN_SCORE:
		_game_over("Player Wins!")
	elif opponent_score >= WIN_SCORE:
		_game_over("Opponent Wins!")
	else:
		await get_tree().create_timer(0.5).timeout
		_reset_rally()

func _update_score() -> void:
	score_label.text = str(player_score) + " - " + str(opponent_score)

func _reset_rally() -> void:
	if game_over:
		return
	point_locked = false
	player.global_position = spawn_player.global_position
	opponent.global_position = spawn_opponent.global_position
	shuttle.global_position = spawn_ball.global_position
	shuttle.linear_velocity = Vector2.ZERO
	shuttle.angular_velocity = 0.0

	message_label.text = serving_player.capitalize() + " to serve"
	await get_tree().create_timer(0.6).timeout
	message_label.text = ""

	var dir := Vector2.LEFT if serving_player == "player" else Vector2.RIGHT
	shuttle.call("serve", dir)

func _game_over(text: String) -> void:
	game_over = true
	message_label.text = ""
	shuttle.linear_velocity = Vector2.ZERO
	shuttle.sleeping = true

	# Show overlay menu
	game_over_label.text = text
	game_over_menu.show()
	
	
func _freeze_shuttle() -> void:
	if shuttle and shuttle.is_inside_tree():
		shuttle.linear_velocity = Vector2.ZERO
		shuttle.angular_velocity = 0.0
		shuttle.sleeping = true
