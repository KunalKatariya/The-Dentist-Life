extends Node2D

@export var dialog_items: Array[DialogItem] = []

func _ready():
	$BGSwitchTimer.connect("timeout", Callable(self, "_on_timer_timeout"))
	if dialog_items.size() > 0:
		# Show the dialog immediately
		DialogSystem.show_dialog(dialog_items)

func _on_timer_timeout():
	$BG1.visible = !$BG1.visible
	$BG2.visible = !$BG2.visible
