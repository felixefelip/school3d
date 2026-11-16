extends Node
## The player's items, shown in the hotbar. This is an autoload
## (PlayerInventory), so the items carry over from one scene to another.

signal selected_changed(index: int)

const SLOTS := 10

var inventory := Inventory.create(SLOTS)
## The hotbar slot picked with the number keys or the mouse wheel.
var selected := 0:
	set(value):
		selected = wrapi(value, 0, SLOTS)
		selected_changed.emit(selected)


func get_selected_item() -> Item:
	return inventory.items[selected]
