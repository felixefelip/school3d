extends "res://scripts/storage.gd"
## The bathroom washing machine: put dirty clothes in and press Wash.

## How long a wash takes (s).
@export var wash_time := 3.0


func perform_action() -> void:
	if busy:
		return
	busy = true
	await get_tree().create_timer(wash_time).timeout
	for item in inventory.items:
		if item and item.is_clothing():
			item.dirty = false
			item.worn_seconds = 0.0
	busy = false
	inventory.emit_changed()
