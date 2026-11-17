class_name HeartRow
extends Control
## A row of hearts, filled up to `filled` (like Stardew Valley's friendship).

const FULL := Color("e0402f")
const EMPTY := Color("f3d9a4")
const OUTLINE := Color("5a3417")
const SIZE := 18.0
const GAP := 4.0

var total := 10:
	set(value):
		total = value
		custom_minimum_size = Vector2(total * (SIZE + GAP) - GAP, SIZE)
		queue_redraw()
var filled := 0:
	set(value):
		filled = value
		queue_redraw()

var _shape := PackedVector2Array()


func _init() -> void:
	total = total
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Heart curve, scaled to SIZE x SIZE with its top-left at (0, 0).
	var points := PackedVector2Array()
	for i in 32:
		var t := TAU * i / 32.0
		points.append(Vector2(16.0 * pow(sin(t), 3), -(13.0 * cos(t) - 5.0 * cos(2 * t) - 2.0 * cos(3 * t) - cos(4 * t))))
	var lo := points[0]
	var hi := points[0]
	for p in points:
		lo = Vector2(minf(lo.x, p.x), minf(lo.y, p.y))
		hi = Vector2(maxf(hi.x, p.x), maxf(hi.y, p.y))
	for p in points:
		_shape.append((p - lo) / (hi - lo) * SIZE)


func _draw() -> void:
	for i in total:
		var offset := Vector2(i * (SIZE + GAP), 0)
		var heart := PackedVector2Array()
		for p in _shape:
			heart.append(p + offset)
		draw_colored_polygon(heart, FULL if i < filled else EMPTY)
		var outline := heart.duplicate()
		outline.append(heart[0])
		draw_polyline(outline, OUTLINE, 1.5, true)
