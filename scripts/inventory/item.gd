class_name Item
extends Resource
## Something the player can carry in an inventory slot. Each item is a .tres
## file under res://items/.

@export var id: String
@export var display_name: String
@export var icon: Texture2D
@export_multiline var description: String
