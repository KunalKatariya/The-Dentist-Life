class_name NPC extends CharacterBody2D

@export var npc_resource : NPCResource

@onready var animation : AnimationPlayer = $AnimationPlayer
@onready var sprite : Sprite2D = $Sprite2D

func _ready():
	setup_npc()
	gather_interactables()
	pass

func setup_npc() -> void:
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
	pass
