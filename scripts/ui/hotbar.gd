extends PanelContainer
## The player's item slots along the bottom of the screen, like the toolbar
## in Stardew Valley. The selected slot (number keys or mouse wheel, handled
## by the player) has a red border.

var _slots: Array[InventorySlot] = []


func _ready() -> void:
	add_theme_stylebox_override("panel", UIStyle.frame())
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	add_child(row)
	for i in PlayerInventory.SLOTS:
		var slot := InventorySlot.new()
		row.add_child(slot)
		slot.setup(PlayerInventory.inventory, i)
		_slots.append(slot)
	PlayerInventory.selected_changed.connect(_on_selected_changed)
	_on_selected_changed(PlayerInventory.selected)


func _on_selected_changed(index: int) -> void:
	for i in _slots.size():
		_slots[i].selected = i == index
