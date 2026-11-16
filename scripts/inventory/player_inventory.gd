extends Node
## The player's items: the hotbar and the clothes she is wearing. This is an
## autoload (PlayerInventory), so both carry over from one scene to another.

signal selected_changed(index: int)

const SLOTS := 10
## Clothes get dirty after being worn this long (s).
const DIRTY_AFTER := 180.0

var inventory := Inventory.create(SLOTS)
## What she wears, one slot per Item.Slot: head, top, legs, feet.
var equipment := Inventory.create(4)
## The hotbar slot picked with the number keys or the mouse wheel.
var selected := 0:
	set(value):
		selected = wrapi(value, 0, SLOTS)
		selected_changed.emit(selected)


func get_selected_item() -> Item:
	return inventory.items[selected]


func _process(delta: float) -> void:
	for item in equipment.items:
		if item == null or item.dirty:
			continue
		item.worn_seconds += delta
		if item.worn_seconds >= DIRTY_AFTER:
			item.dirty = true
			equipment.emit_changed()
