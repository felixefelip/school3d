extends PanelContainer
## Window listing a storage's slots (such as the wardrobe). Items are dragged
## between it and the hotbar. The player opens and closes it.

const COLUMNS := 6

var _title := Label.new()
var _grid := GridContainer.new()


func _ready() -> void:
	add_theme_stylebox_override("panel", UIStyle.frame())
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	add_child(column)

	UIStyle.style_label(_title, 28)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(_title)

	_grid.columns = COLUMNS
	_grid.add_theme_constant_override("h_separation", 4)
	_grid.add_theme_constant_override("v_separation", 4)
	column.add_child(_grid)

	var hint := Label.new()
	UIStyle.style_label(hint, 18)
	hint.text = "Drag items to your inventory below  ·  [E] Close"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(hint)
	hide()


func open(title: String, inventory: Inventory) -> void:
	_title.text = title
	for old in _grid.get_children():
		old.queue_free()
	for i in inventory.size():
		var slot := InventorySlot.new()
		_grid.add_child(slot)
		slot.setup(inventory, i)
	show()


func close() -> void:
	hide()
