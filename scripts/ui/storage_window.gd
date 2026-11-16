extends PanelContainer
## Window listing a storage's slots (such as the wardrobe). Items are dragged
## between it and the hotbar. The player opens and closes it. Storages with
## an action (the washing machine) get a button under the slots.

const COLUMNS := 6

var _title := Label.new()
var _grid := GridContainer.new()
var _action := Button.new()
var _storage: Node


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
	_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(_grid)

	UIStyle.style_button(_action)
	_action.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_action.pressed.connect(func() -> void: _storage.perform_action())
	column.add_child(_action)

	var hint := Label.new()
	UIStyle.style_label(hint, 18)
	hint.text = "Drag items to your inventory below  ·  [E] Close"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(hint)
	hide()


func open(storage: Node) -> void:
	_storage = storage
	_title.text = storage.title
	_grid.columns = mini(COLUMNS, storage.inventory.size())
	# Removed right away (not just queued), so the window shrinks to the new
	# slot count when it is resized below.
	for old in _grid.get_children():
		_grid.remove_child(old)
		old.queue_free()
	for i in storage.inventory.size():
		var slot := InventorySlot.new()
		_grid.add_child(slot)
		slot.setup(storage.inventory, i)
	_action.visible = storage.action_name != ""
	show()
	reset_size()


func close() -> void:
	hide()
	_storage = null


func _process(_delta: float) -> void:
	if _storage and _action.visible:
		_action.disabled = _storage.busy
		_action.text = "Washing..." if _storage.busy else _storage.action_name
