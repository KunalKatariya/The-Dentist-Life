extends Node

const PLAYER = preload("res://Player/player.tscn")

signal camera_shook( trauma : float )
signal interact_pressed
signal player_leveled_up

var interact_handled : bool = true
var player : Player
var player_spawned : bool = false



func _ready() -> void:
	pass
