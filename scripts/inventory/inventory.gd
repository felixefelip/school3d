class_name Inventory
extends Resource
## A fixed number of item slots; empty slots are null. Emits `changed`
## whenever a slot's contents change.

@export var items: Array[Item] = []


static func create(slot_count: int) -> Inventory:
	var inventory := Inventory.new()
	inventory.items.resize(slot_count)
	return inventory


func size() -> int:
	return items.size()


## Puts the item in the first empty slot. Returns false if the inventory is full.
func add(item: Item) -> bool:
	var index := items.find(null)
	if index < 0:
		return false
	items[index] = item
	emit_changed()
	return true


## Moves the item in from[from_index] to to[to_index], swapping it with
## whatever was there. Works within one inventory or between two.
static func move(from: Inventory, from_index: int, to: Inventory, to_index: int) -> void:
	if from == to and from_index == to_index:
		return
	var moving := from.items[from_index]
	from.items[from_index] = to.items[to_index]
	to.items[to_index] = moving
	from.emit_changed()
	if to != from:
		to.emit_changed()
