class_name NPC extends CharacterBody2D

@export var npc_resource : NPCResource

@onready var animation : AnimationPlayer = $AnimationPlayer
@onready var sprite : Sprite2D = $Sprite2D

func _ready():
	setup_npc()
	gather_interactables()
	pass

func setup_npc() -> void:
	animation.play("idle")
	if npc_resource:
		sprite.texture = npc_resource.sprite
	pass
	
func gather_interactables() -> void:
	for c in get_children():
		if c is DialogInteraction:
			c.player_interacted.connect( _on_player_interacted )
			c.finished.connect( _on_interaction_finished)
			
func _on_player_interacted() -> void:
	pass

func _on_interaction_finished() -> void:
	print("[NPC] DialogInteraction finished signal received!")
	var playground = get_tree().get_current_scene()
	if playground.has_method("_on_npc_dialog_finished"):
		print("[NPC] Calling Playground._on_npc_dialog_finished()")
		playground._on_npc_dialog_finished(self)
	else:
		print("[NPC] Playground missing _on_npc_dialog_finished()")
	pass
