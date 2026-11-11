class_name VillainResource extends Resource

@export var id: StringName = &""
@export var display_name: String = ""
@export var sprite: Texture2D
## Used for the name, portrait and voice pitch in dialog.
@export var npc_info: NPCResource
@export var challenge_scene: PackedScene
@export var guarded_item_id: StringName = &""

## Lines shown before the challenge. Prefix a line with "player:" for
## Dr. Gunika, or "me:" for the villain. Unprefixed lines are the villain.
@export var intro_lines: PackedStringArray = []
## Lines shown after a successful challenge. Same prefix rules.
@export var victory_lines: PackedStringArray = []
## Lines shown when the player leaves the challenge. Same prefix rules.
@export var retreat_lines: PackedStringArray = []


func cleared_flag() -> String:
	return "villain_%s_cleared" % id
