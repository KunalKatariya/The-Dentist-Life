class_name ItemCatalog extends RefCounted
## The six pieces of clinic equipment that must be recovered.
## The reception bell is separate: it belongs to the finale.

const ITEMS := [
	preload("res://Data/items/mirror_set.tres"),
	preload("res://Data/items/chair.tres"),
	preload("res://Data/items/curing_light.tres"),
	preload("res://Data/items/xray.tres"),
	preload("res://Data/items/sterilizer.tres"),
	preload("res://Data/items/records.tres"),
]

const TOTAL := 6
const BELL_ID := &"bell"


static func get_item(id: StringName) -> ItemResource:
	for item in ITEMS:
		if item.id == id:
			return item
	return null


static func display_name(id: StringName) -> String:
	var item := get_item(id)
	return item.display_name if item != null else String(id)
