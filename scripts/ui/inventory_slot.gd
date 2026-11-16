class_name InventorySlot
extends PanelContainer
## One inventory slot on screen. Items are moved by dragging them with the
## mouse onto another slot, in the same inventory or another one; dropping on
## an occupied slot swaps the two items.

const SIZE := 64

var inventory: Inventory
var index: int
## The item in this slot, or null.
var item: Item:
	get:
		return inventory.items[index] if inventory else null
## Highlighted with a red border (the hotbar's selected slot).
var selected := false:
	set(value):
		selected = value
		add_theme_stylebox_override("panel", UIStyle.slot(selected))

var _icon := TextureRect.new()


func _init() -> void:
	custom_minimum_size = Vector2(SIZE, SIZE)
	add_theme_stylebox_override("panel", UIStyle.slot(false))
	_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_icon)


func setup(slot_inventory: Inventory, slot_index: int) -> void:
	inventory = slot_inventory
	index = slot_index
	inventory.changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	_icon.texture = item.icon if item else null


func _get_drag_data(_at_position: Vector2) -> Variant:
	if item == null:
		return null
	# The preview follows the mouse by its top-left corner, so the icon is
	# offset inside a holder to sit centered under the cursor.
	var preview := TextureRect.new()
	preview.texture = item.icon
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.size = Vector2(SIZE, SIZE) * 0.8
	preview.position = -preview.size / 2.0
	var holder := Control.new()
	holder.add_child(preview)
	set_drag_preview(holder)
	_icon.modulate.a = 0.35
	return {"inventory": inventory, "index": index}


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.get("inventory") is Inventory


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	Inventory.move(data.inventory, data.index, inventory, index)


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		_icon.modulate.a = 1.0
