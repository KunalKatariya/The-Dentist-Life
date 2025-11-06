extends Control

@export var is_player: bool = false

# Useful constants
const EXPAND = Control.SIZE_EXPAND_FILL
const FILL = Control.SIZE_FILL

func _ready():
	# ensure label wraps
	$BubblePanel/Label.autowrap_mode = TextServer.AUTOWRAP_WORD


func set_text(text: String) -> void:
	$BubblePanel/Label.text = text
	_update_alignment_and_style()

func _update_alignment_and_style() -> void:
	# If player message -> push to right: LeftSpacer expands, RightSpacer minimal
	# If npc message -> push to left: RightSpacer expands, LeftSpacer minimal
	if is_player:
		$LeftSpacer.size_flags_horizontal = EXPAND
		$RightSpacer.size_flags_horizontal = FILL
		# style: player bubble color
		$BubblePanel.modulate = Color(0.2, 0.45, 0.95, 1.0)  # bluish
		$BubblePanel.add_theme_color_override("font_color", Color(1,1,1))
		$BubblePanel.add_theme_constant_override("corner_radius", 8) # if using stylebox
	else:
		$LeftSpacer.size_flags_horizontal = FILL
		$RightSpacer.size_flags_horizontal = EXPAND
		# style: npc bubble color
		$BubblePanel.modulate = Color(0.9, 0.9, 0.9, 1.0)  # light grey
		$BubblePanel.add_theme_color_override("font_color", Color(0,0,0))
		$BubblePanel.add_theme_constant_override("corner_radius", 8)
